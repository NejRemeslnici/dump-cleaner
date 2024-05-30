# frozen_string_literal: true

module DumpCleaner
  module Cleaners
    class MysqlShellDumpCleaner < BaseCleaner
      require "json"
      require "open3"
      require "zlib"
      require "fileutils"

      def pre_cleanup
        prepare_destination_dump
      end

      def clean
        config.table_cleanups.each do |table_cleanup|
          puts "Cleaning table #{table_cleanup.db}.#{table_cleanup.table}…"

          DumpCleaner::CleanupData::Uniqueness::Ensurer.instance.clear

          @table_info = table_info(db: table_cleanup.db, table: table_cleanup.table)
          table_file_part = "#{table_cleanup.db}@#{table_cleanup.table}"

          Dir.glob("#{options[:source_dump_path]}/#{table_file_part}@@*.tsv.zst").each do |file|
            Open3.pipeline_r(["zstd", "-dc", file], ["head", "-n", "10000000"]) do |tsv_data, wait_thread|
              destination_file = file.sub(options[:source_dump_path], options[:destination_dump_path])

              Open3.pipeline_w(["zstd", "-qfo", destination_file]) do |zstd_out, _wait_thread|
                tsv_data.each_line do |line|
                  zstd_out.print cleaned_line(line, table_cleanup:)
                end
              end
            end
          end

          puts
        end
      end

      def post_cleanup
        Dir.glob("#{options[:source_dump_path]}/*").each do |file|
          destination_file = file.sub(options[:source_dump_path], options[:destination_dump_path])
          FileUtils.cp(file, destination_file, preserve: true) unless File.exist?(destination_file)
        end
      end

      private

      def table_info(db:, table:)
        JSON.parse(File.read("#{options[:source_dump_path]}/#{db}@#{table}.json"))
      end

      def prepare_destination_dump
        Dir.mkdir(options[:destination_dump_path]) unless Dir.exist?(options[:destination_dump_path])
      end

      def cleaned_line(line, table_cleanup:)
        record = line.split("\t")
        record_context = record_context(record, table_cleanup:)
        print "\r#{record_context['id']}… " if (record_context["id"].to_i % 10_000).zero?

        keep_record = keep_record?(record_context, table_cleanup:)

        table_cleanup.columns.each do |column|
          column_index = @table_info.dig("options", "columns").index(column.name)
          raise "Invalid column specified in config: #{column.name}" unless column_index

          next if record[column_index] == "\\N" # ignore NULL values

          record[column_index] = cleanup_data.clean(type: column.cleanup_type,
                                                    orig_value: record[column_index],
                                                    record: record_context,
                                                    keep_record:)
        end

        new_line = record.join("\t")
        warn_on_changed_line_length(line, new_line, id: record_context["id"], record:)

        new_line
      end

      def record_context(record, table_cleanup:)
        columns = @table_info.dig("options", "columns")
        indexes = columns.each_with_index.to_h
        columns &= table_cleanup.record_context_columns
        columns.each_with_object({}) { |column, context| context[column] = record[indexes[column]] }
      end

      def keep_record?(record, table_cleanup:)
        return false unless table_cleanup.keep_same_conditions

        Conditions.new(table_cleanup.keep_same_conditions).evaluate_to_true?(record)
      end

      def warn_on_changed_line_length(orig_line, new_line, id:, record:)
        return if orig_line.bytes.length == new_line.bytes.length

        warn "ID: #{id} bytes length changed: #{orig_line.bytes.length} => #{new_line.bytes.length}"
        orig_line.split("\t").each_with_index do |column, i|
          warn "#{column} -> #{record[i]}" if !record[i] || column.bytes.length != record[i].bytes.length
        end
      end
    end
  end
end
