# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"

RSpec.describe DumpCleaner::Cleaners::MysqlShellDumpCleaner do
  let(:config) do
    instance_double(DumpCleaner::Config, cleanup_tables: [%w[db table1], %w[db table2]])
  end

  describe "#pre_cleanup" do
    it "checks if the source dump path exists" do
      options = instance_double(DumpCleaner::Options, source_dump_path: "non_existent",
                                                      destination_dump_path: "dest_dump")

      expect { described_class.new(config:, options:).pre_cleanup }.to raise_error(/Source dump path does not exist/)
    end

    it "creates the destination dump directory" do
      Dir.mktmpdir do |dir|
        options = instance_double(DumpCleaner::Options, source_dump_path: "#{dir}/source_dump",
                                                        destination_dump_path: "#{dir}/dest_dump")
        Dir.mkdir("#{dir}/source_dump")
        expect(Dir.exist?("#{dir}/dest_dump")).to be false

        described_class.new(config:, options:).pre_cleanup
        expect(Dir.exist?("#{dir}/dest_dump")).to be true
      end
    end
  end

  describe "#clean" do
    it "calls the MysqlShellTableCleaner hooks for each table" do
      options = instance_double(DumpCleaner::Options, source_dump_path: "source_dump",
                                                      destination_dump_path: "dest_dump")

      cleaner1 = instance_double(DumpCleaner::Cleaners::MysqlShellTableCleaner)
      expect(DumpCleaner::Cleaners::MysqlShellTableCleaner)
        .to receive(:new).with(db: "db", table: "table1", config:, options:)
        .and_return(cleaner1)
      expect(cleaner1).to receive(:pre_cleanup)
      expect(cleaner1).to receive(:clean)
      expect(cleaner1).to receive(:post_cleanup)

      cleaner2 = instance_double(DumpCleaner::Cleaners::MysqlShellTableCleaner)
      expect(DumpCleaner::Cleaners::MysqlShellTableCleaner)
        .to receive(:new).with(db: "db", table: "table2", config:, options:)
        .and_return(cleaner2)
      expect(cleaner2).to receive(:pre_cleanup)
      expect(cleaner2).to receive(:clean)
      expect(cleaner2).to receive(:post_cleanup)

      described_class.new(config:, options:).clean
    end
  end

  describe "#post_cleanup" do
    it "copies all non-existent files to destination" do
      Dir.mktmpdir do |dir|
        options = instance_double(DumpCleaner::Options, source_dump_path: "#{dir}/source_dump",
                                                        destination_dump_path: "#{dir}/dest_dump")
        Dir.mkdir("#{dir}/source_dump")
        FileUtils.touch("#{dir}/source_dump/file1")
        FileUtils.touch("#{dir}/source_dump/file2")
        FileUtils.touch("#{dir}/source_dump/file3")

        Dir.mkdir("#{dir}/dest_dump")
        FileUtils.touch("#{dir}/dest_dump/file2")

        described_class.new(config:, options:).post_cleanup
        expect(File.exist?("#{dir}/dest_dump/file1")).to be true
        expect(File.exist?("#{dir}/dest_dump/file3")).to be true
      end
    end
  end

  describe "integration tests" do
    it "cleans the mysql shell dump" do
      Dir.mktmpdir do |dir|
        system("ruby -Ilib exe/dump_cleaner -f spec/support/data/mysql_shell_dump -t #{dir} \
                -c spec/support/data/mysql_shell_dump_cleaner.yml")

        expect(File.exist?("#{dir}/db@users@@0.tsv.zst")).to be true

        output = `zstd -dc #{dir}/db@users@@0.tsv.zst`
        expect(output).to include("1\tJackson\tvariety@gmail.com\t+420774443735\n")
        expect(output).to include("2\tAllen\tcontains@present.com\t+420733637921\n")
        expect(output).to include("3\tHarrison\tshould.visitors@program.com\tN/A\n")
      end
    end
  end
end
