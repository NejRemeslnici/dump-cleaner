# frozen_string_literal: true

module DumpCleaner
  module Cleaners
    class MysqlShellDumpCleaner < BaseCleaner
      require "fileutils"

      include MysqlShellDumpHelpers

      def pre_cleanup
        validate_source_dump
        prepare_destination_dump
      end

      def clean
        config.cleanup_tables.each do |db, table|
          table_cleaner = MysqlShellTableCleaner.new(db:, table:, config:, options:)

          table_cleaner.pre_cleanup
          table_cleaner.clean
          table_cleaner.post_cleanup
        end
      end

      def post_cleanup
        copy_remaining_files
      end

      private

      def validate_source_dump
        raise "Source dump path does not exist: #{options.source_dump_path}" unless Dir.exist?(options.source_dump_path)
      end

      def prepare_destination_dump
        Dir.mkdir(options.destination_dump_path) unless Dir.exist?(options.destination_dump_path)
      end

      def copy_remaining_files
        Dir.glob("#{options.source_dump_path}/*").each do |file|
          destination_file = destination_file_for(file)
          FileUtils.cp(file, destination_file, preserve: true) unless File.exist?(destination_file)
        end
      end
    end
  end
end
