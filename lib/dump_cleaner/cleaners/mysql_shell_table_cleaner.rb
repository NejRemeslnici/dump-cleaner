# frozen_string_literal: true

module DumpCleaner
  module Cleaners
    class MysqlShellTableCleaner < BaseCleaner
      require "open3"

      include MysqlShellDumpHelpers

      attr_reader :table_info, :cleanup_data, :cleaning

      def initialize(db:, table:, config:, options:)
        super(config:, options:)
        @db = db
        @table = table
        @cleanup_data = Cleanup::DataSource.new(config:)
        @cleaning = Cleanup::Cleaning.new(config:)
      end

      def pre_cleanup
        @table_info = DumpTableInfo.load(db: @db, table: @table, source_dump_path: options.source_dump_path)
        validate_table_info
      end

      def clean
        table_config = config.cleanup_table_config(db: @db, table: @table)
        Log.info { "Cleaning table #{table_info.db_dot_table}…" }

        DumpCleaner::Cleanup::Uniqueness::CaseInsensitiveCache.instance.clear

        Dir.glob("#{options.source_dump_path}/#{table_info.db_at_table}@@*.#{table_info.extension}").each do |file|
          # Open3.pipeline_r(pipe_source_args(file), ["head", "-n", "1000"]) do |tsv_data, _wait_thread|
          Open3.pipeline_r(pipe_source_args(file)) do |tsv_data, _wait_thread|
            Open3.pipeline_w(pipe_sink_args(destination_file_for(file))) do |zstd_out, _wait_thread|
              tsv_data.each_line do |line|
                zstd_out.print clean_line(line, table_config:)
              end
            end
          end
        end
      end

      private

      def clean_line(line, table_config:)
        record = line.split("\t")
        record_context = record_context(record, table_config:)
        print "\r#{record_context['id']}… " if (record_context["id"].to_i % 10_000).zero?

        keep_record = keep_same_record?(record_context, table_config:)

        table_config.columns.each do |column_config|
          column_index = table_info.column_index(column_config.name)
          raise "Invalid column specified in config: #{column_config.name}" unless column_index

          next if record[column_index] == "\\N" # ignore NULL values

          cleanup_data_for_type = cleanup_data.data_for(column_config.cleanup_type)

          record[column_index] = cleaning.clean_value_for(record[column_index],
                                                          type: column_config.cleanup_type,
                                                          cleanup_data: cleanup_data_for_type,
                                                          record: record_context,
                                                          keep_record:,
                                                          column_config:)
        end

        new_line = record.join("\t")
        warn_on_changed_line_length(line, new_line, id: record_context["id"], record:)

        new_line
      end

      def record_context(record, table_config:)
        columns = table_config.record_context_columns
        context = columns.each_with_object({}) do |column, context|
          context[column] = record[table_info.column_index(column)]
        end
        context["id_column"] = record[table_info.column_index(table_config.id_column)]
        context
      end

      def warn_on_changed_line_length(orig_line, new_line, id:, record:)
        return if orig_line.bytesize == new_line.bytesize

        warning = "ID: #{id} bytesize changed: #{orig_line.bytesize} => #{new_line.bytesize}"
        orig_line.split("\t").each_with_index do |column, i|
          warning << "#{column} -> #{record[i]}" if !record[i] || column.bytesize != record[i].bytesize
        end

        Log.error { warning }
      end

      def validate_table_info
        case table_info.compression
        when "zstd"
          system("zstd --version >/dev/null 2>&1") || raise("zstd not found in \$PATH")
        else
          raise "Unsupported dump compression format '#{table_info.compression}'"
        end
      end

      def pipe_source_args(file)
        case table_info.compression
        when "zstd"
          ["zstd", "-dc", file]
        end
      end

      def pipe_sink_args(file)
        case table_info.compression
        when "zstd"
          ["zstd", "-qfo", file]
        end
      end

      class DumpTableInfo
        require "json"

        def self.load(db:, table:, source_dump_path:)
          new(JSON.parse(File.read(table_info_file_path(db:, table:, source_dump_path:))))
        end

        def self.table_info_file_path(db:, table:, source_dump_path:)
          "#{source_dump_path}/#{db}@#{table}.json"
        end

        def initialize(table_info)
          @table_info = table_info
        end

        def db
          @db ||= @table_info.dig("options", "schema")
        end

        def table
          @table ||= @table_info.dig("options", "table")
        end

        def db_dot_table
          "#{db}.#{table}"
        end

        def db_at_table
          "#{db}@#{table}"
        end

        def compression
          @table_info["compression"]
        end

        def extension
          @table_info["extension"]
        end

        def columns
          @columns ||= @table_info.dig("options", "columns")
        end

        def column_index(name)
          columns.index(name)
        end
      end
    end
  end
end
