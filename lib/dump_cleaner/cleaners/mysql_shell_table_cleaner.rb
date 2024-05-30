# frozen_string_literal: true

module DumpCleaner
  module Cleaners
    class MysqlShellTableCleaner < BaseCleaner
      require "open3"

      include MysqlShellDumpHelpers

      def initialize(db:, table:, config:, options:, cleanup_data:)
        super(config:, options:)
        @db = db
        @table = table
        @cleanup_data = cleanup_data
      end

      def pre_cleanup
        @table_info = DumpTableInfo.load(db: @db, table: @table, source_dump_path: options.source_dump_path)
      end

      def clean
        table_config = config.cleanup_table_config(db: @db, table: @table)
        puts "Cleaning table #{@table_info.db_dot_table}…"

        DumpCleaner::Cleanup::Uniqueness::Ensurer.instance.clear

        Dir.glob("#{options.source_dump_path}/#{@table_info.db_at_table}@@*.tsv.zst").each do |file|
          Open3.pipeline_r(["zstd", "-dc", file], ["head", "-n", "10000000"]) do |tsv_data, _wait_thread|
            Open3.pipeline_w(["zstd", "-qfo", destination_file_for(file)]) do |zstd_out, _wait_thread|
              tsv_data.each_line do |line|
                zstd_out.print clean_line(line, table_config:)
              end
            end
          end
        end

        puts
      end

      private

      def clean_line(line, table_config:)
        record = line.split("\t")
        record_context = record_context(record, table_config:)
        print "\r#{record_context['id']}… " if (record_context["id"].to_i % 10_000).zero?

        keep_record = keep_record?(record_context, table_config:)

        table_config.columns.each do |column|
          column_index = @table_info.column_index(column.name)
          raise "Invalid column specified in config: #{column.name}" unless column_index

          next if record[column_index] == "\\N" # ignore NULL values

          record[column_index] = @cleanup_data.clean(type: column.cleanup_type,
                                                     orig_value: record[column_index],
                                                     record: record_context,
                                                     keep_record:)
        end

        new_line = record.join("\t")
        warn_on_changed_line_length(line, new_line, id: record_context["id"], record:)

        new_line
      end

      def record_context(record, table_config:)
        columns = table_config.record_context_columns
        columns.each_with_object({}) { |column, context| context[column] = record[@table_info.column_index(column)] }
      end

      def keep_record?(record, table_config:)
        return false unless table_config.keep_same_conditions

        Conditions.new(table_config.keep_same_conditions).evaluate_to_true?(record)
      end

      def warn_on_changed_line_length(orig_line, new_line, id:, record:)
        return if orig_line.bytes.length == new_line.bytes.length

        warn "ID: #{id} bytes length changed: #{orig_line.bytes.length} => #{new_line.bytes.length}"
        orig_line.split("\t").each_with_index do |column, i|
          warn "#{column} -> #{record[i]}" if !record[i] || column.bytes.length != record[i].bytes.length
        end
      end

      class DumpTableInfo
        require "json"

        def self.load(db:, table:, source_dump_path:)
          new(JSON.parse(File.read("#{source_dump_path}/#{db}@#{table}.json")))
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
