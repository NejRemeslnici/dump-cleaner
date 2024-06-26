# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe DumpCleaner::Cleaners::MysqlShellTableCleaner do
  let(:table_config) do
    instance_double(DumpCleaner::Config::CleanupTableConfig,
                    db: "db",
                    table: "table",
                    columns: [
                      DumpCleaner::Config::CleanupTableColumnConfig.new(name: "name", cleanup_type: "name",
                                                                        unique: false),
                      DumpCleaner::Config::CleanupTableColumnConfig.new(name: "email", cleanup_type: "email",
                                                                        unique: false)
                    ],
                    record_context_columns: %w[id name email],
                    keep_same_record_conditions: [])
  end

  let(:config) do
    instance_double(DumpCleaner::Config, cleanup_table_config: table_config)
  end

  let(:options) do
    instance_double(DumpCleaner::Options, source_dump_path: "source_dump", destination_dump_path: "dest_dump")
  end

  let(:record_context) do
    { "id" => "1", "name" => "Some Name", "email" => "someone@example.com" }
  end

  let(:cleaner) { described_class.new(db: "db", table: "table", config:, options:) }

  def table_info(compression: "zstd")
    table_info_class = DumpCleaner::Cleaners::MysqlShellTableCleaner::DumpTableInfo
    table_info = instance_double(table_info_class,
                                 db_dot_table: "db.table",
                                 db_at_table: "db@table",
                                 compression:,
                                 extension: "tsv.zst",
                                 dialect: table_info_class::DialectOptions.new(lines_terminated_by: "\n",
                                                                               fields_terminated_by: "\t",
                                                                               fields_enclosed_by: "",
                                                                               fields_optionally_enclosed: false,
                                                                               fields_escaped_by: "\\"))
    allow(table_info).to receive(:column_index).with("id").and_return(0)
    allow(table_info).to receive(:column_index).with("name").and_return(1)
    allow(table_info).to receive(:column_index).with("email").and_return(2)

    table_info
  end

  describe "#pre_cleanup" do
    it "calls the DumpTableInfo to load the table info JSON file from the dump" do
      expect(described_class::DumpTableInfo).to receive(:load).with(db: "db", table: "table",
                                                                    source_dump_path: "source_dump")
                                                              .and_return(table_info)
      cleaner.pre_cleanup
    end

    it "raises error if unsupported compression format found in table info" do
      expect(described_class::DumpTableInfo).to receive(:load).with(db: "db", table: "table",
                                                                    source_dump_path: "source_dump")
                                                              .and_return(table_info(compression: "unknown"))
      expect { cleaner.pre_cleanup }.to raise_error("Unsupported dump compression format 'unknown'")
    end

    it "raises error if the proper compression program not found in PATH" do
      expect(described_class::DumpTableInfo).to receive(:load).with(db: "db", table: "table",
                                                                    source_dump_path: "source_dump")
                                                              .and_return(table_info)

      with_modified_env("PATH" => "") do
        expect { cleaner.pre_cleanup }.to raise_error("zstd not found in \$PATH")
      end
    end
  end

  describe "#clean" do
    def open_pipe(data:)
      expect(Dir).to receive(:glob).with("source_dump/db@table@@*.tsv.zst")
                                   .and_return(["source_dump/db@table@@file.tsv.zst"])
      expect(cleaner).to receive(:table_info).at_least(:once).and_return(table_info)

      expect(Open3).to receive(:pipeline_r).with(["zstd", "-dc", "source_dump/db@table@@file.tsv.zst"])
                                           .and_yield(data, nil)
      zstd_out = instance_double(IO, print: nil)
      expect(Open3).to receive(:pipeline_w).with(["zstd", "-qfo", "dest_dump/db@table@@file.tsv.zst"])
                                           .and_yield(zstd_out, nil)
      zstd_out
    end

    it "lists all data files in the dump, opens a read-write pipe for them" do
      open_pipe(data: "")
      cleaner.clean
    end

    it "calls clean_line for each data line and writes its return value to the pipe sink" do
      zstd_out = open_pipe(data: "1\tSome Name\tsomeone@example.com\n")

      expect(cleaner).to receive(:clean_line)
        .with("1\tSome Name\tsomeone@example.com", table_config: config.cleanup_table_config(db: "db", table: "table"))
        .and_return("1\tDiff Name\tanybody@example.com")

      expect(zstd_out).to receive(:print).with("1\tDiff Name\tanybody@example.com\n")

      cleaner.clean
    end

    it "calls the data_source and cleaning workflows for each data column" do
      open_pipe(data: "1\tSome Name\tsomeone@example.com")

      expect(cleaner).to receive(:record_context).with(["1", "Some Name", "someone@example.com"], table_config:)
                                                 .and_return(record_context)

      expect(cleaner.cleanup_data).to receive(:data_for).with("name").and_return(["Diff Name"])
      expect(cleaner.cleanup_data).to receive(:data_for).with("email").and_return(["anybody@example.com"])

      expect(cleaner.cleaning).to receive(:clean_value_for).with("Some Name",
                                                                 type: "name",
                                                                 cleanup_data: ["Diff Name"],
                                                                 record: record_context,
                                                                 keep_record: false,
                                                                 column_config: table_config.columns[0])
                                                           .and_return("Diff Name")

      expect(cleaner.cleaning).to receive(:clean_value_for).with("someone@example.com",
                                                                 type: "email",
                                                                 cleanup_data: ["anybody@example.com"],
                                                                 record: record_context,
                                                                 keep_record: false,
                                                                 column_config: table_config.columns[1])
                                                           .and_return("anybody@example.com")

      cleaner.clean
    end

    it "prints error when the cleaned line bytesize differs" do
      open_pipe(data: "1\tSome Name\tsomeone@example.com")

      expect(cleaner).to receive(:record_context).with(["1", "Some Name", "someone@example.com"], table_config:)
                                                 .and_return(record_context)

      expect(cleaner.cleanup_data).to receive(:data_for).with("name").and_return(nil)
      expect(cleaner.cleanup_data).to receive(:data_for).with("email").and_return(nil)

      expect(cleaner.cleaning).to receive(:clean_value_for).with("Some Name",
                                                                 type: "name",
                                                                 cleanup_data: nil,
                                                                 record: record_context,
                                                                 keep_record: false,
                                                                 column_config: table_config.columns[0])
                                                           .and_return("Foo")

      expect(cleaner.cleaning).to receive(:clean_value_for).with("someone@example.com",
                                                                 type: "email",
                                                                 cleanup_data: nil,
                                                                 record: record_context,
                                                                 keep_record: false,
                                                                 column_config: table_config.columns[1])
                                                           .and_return("foo@example.com")

      log = DumpCleaner::Log.instance
      block = lambda do
        log.reopen($stdout)
        cleaner.clean
      end

      expect(&block).to output(/ID: 1 bytesize changed: 31 => 21/).to_stdout
    end
  end

  describe DumpCleaner::Cleaners::MysqlShellTableCleaner::DumpTableInfo do
    describe ".table_info_file_path" do
      it "finds the proper JSON file to load" do
        expect(described_class.table_info_file_path(db: "db", table: "table", source_dump_path: "source_dump"))
          .to eq("source_dump/db@table.json")
      end
    end

    describe ".load" do
      it "loads the JSON file" do
        Tempfile.create("table_info") do |file|
          file.write({ "options" => { "columns" => %w[id name email], "schema" => "db", "table" => "table" } }.to_json)
          file.close

          expect(described_class).to receive(:table_info_file_path).and_return(file.path)
          described_class.load(db: "db", table: "table", source_dump_path: "source_dump")
        end
      end

      it "raises error if the JSON file is not found" do
        expect(described_class).to receive(:table_info_file_path).and_return("non_existent.json")
        expect { described_class.load(db: "db", table: "table", source_dump_path: "source_dump") }
          .to raise_error(/Table info file not found/)
      end
    end

    context "with parsed data" do
      let(:table_info) do
        described_class.new({ "options" => { "columns" => %w[id name email], "schema" => "db", "table" => "table",
                                             "fieldsTerminatedBy" => "\t", "fieldsEnclosedBy" => "",
                                             "fieldsOptionallyEnclosed" => false, "fieldsEscapedBy" => "\\",
                                             "linesTerminatedBy" => "\n" },
                              "compression" => "zstd", "extension" => "tsv.zst" })
      end

      it "returns the parsed data" do
        expect(table_info.db).to eq("db")
        expect(table_info.table).to eq("table")
        expect(table_info.columns).to eq(%w[id name email])
        expect(table_info.compression).to eq("zstd")
        expect(table_info.extension).to eq("tsv.zst")
      end

      describe "#db_dot_table" do
        it "returns the db.table string" do
          expect(table_info.db_dot_table).to eq("db.table")
        end
      end

      describe "#db_at_table" do
        it "returns the db@table string" do
          expect(table_info.db_at_table).to eq("db@table")
        end
      end

      describe "#column_index" do
        it "returns the index of the given column" do
          expect(table_info.column_index("name")).to eq(1)
        end
      end

      describe "#dialect" do
        it "returns the DialectOptions object with parsed dialect options" do
          expect(table_info.dialect.fields_terminated_by).to eq("\t")
          expect(table_info.dialect.fields_enclosed_by).to eq("")
          expect(table_info.dialect.fields_optionally_enclosed).to eq(false)
          expect(table_info.dialect.fields_escaped_by).to eq("\\")
          expect(table_info.dialect.lines_terminated_by).to eq("\n")
        end
      end
    end
  end
end
