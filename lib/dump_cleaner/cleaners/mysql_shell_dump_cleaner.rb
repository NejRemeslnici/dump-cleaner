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
        config["cleanups"].each do |cleanup|
          @table_info = table_info(db: cleanup["db"], table: cleanup["table"])
          table_file_part = "#{cleanup['db']}@#{cleanup['table']}"

          Dir.glob("#{options[:source_dump_path]}/#{table_file_part}@@*.tsv.zst").each do |file|
            p file
            Open3.pipeline_r(["zstd", "-dc", file], ["head", "-n", "10000000"]) do |tsv_data, wait_thread|
              destination_file = file.sub(options[:source_dump_path], options[:destination_dump_path])
              p destination_file

              Open3.pipeline_w(["zstd", "-qfo", destination_file]) do |zstd_out, wait_thread|
                tsv_data.each_line do |line|
                  zstd_out.print cleaned_line(line, cleanup:)
                end
              end
            end
          end
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

      def cleaned_line(line, cleanup:)
        record = line.split("\t")
        record_context = record_context(record)
        print "\r#{record_context['id']}… " if (record_context["id"].to_i % 10_000).zero?

        return line if ignore_record?(record_context, cleanup:)

        cleanup["columns"].each do |column|
          column_index = @table_info.dig("options", "columns").index(column["name"])

          next if record[column_index] == "\\N" # ignore NULL values

          record[column_index] = cleanup_data.clean(type: column["cleanup_data_type"],
                                                    orig_value: record[column_index],
                                                    record: record_context)
        end

        record.join("\t")
      end

      def record_context(record)
        @table_info.dig("options", "columns").each_with_index.each_with_object({}) do |(column, i), context|
          context[column] = record[i]
        end
      end

      def ignore_record?(record, cleanup:)
        return false unless cleanup["ignore_if"]

        Array(cleanup["ignore_if"]).map do |ignore_if|
          column = ignore_if["column"]
          condition_value = ignore_if["value"]

          conversion, op, value = case ignore_if["condition"]
                                  when "eq"
                                    [nil, "==", condition_value]
                                  when "ne"
                                    [nil, "!=", condition_value]
                                  when "non_zero"
                                    [:to_i, "!=", 0]
                                  when "end_with"
                                    [nil, :end_with?, condition_value]
                                  else
                                    raise "Unknown condition #{ignore_if['condition']} for column #{column}"
                                  end
          record[column].send(conversion || :itself).send(op, value)
        end.any?
      end
    end
  end
end
