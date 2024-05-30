# frozen_string_literal: true

module DumpCleaner
  module Cleaners
    class MysqlShellDumpCleaner < BaseCleaner
      require "fileutils"

      def pre_cleanup
        prepare_destination_dump
      end

      def clean
        cleanup_data = CleanupData::Data.new(config:)

        config.cleanup_tables.each do |db, table|
          table_cleaner = MysqlShellTableCleaner.new(db:, table:, config:, options:, cleanup_data:)

          table_cleaner.pre_cleanup
          table_cleaner.clean
          table_cleaner.post_cleanup
        end
      end

      def post_cleanup
        copy_remaining_files
      end

      private

      def prepare_destination_dump
        Dir.mkdir(options.destination_dump_path) unless Dir.exist?(options.destination_dump_path)
      end

      def copy_remaining_files
        Dir.glob("#{options.source_dump_path}/*").each do |file|
          destination_file = file.sub(options.source_dump_path, options.destination_dump_path)
          FileUtils.cp(file, destination_file, preserve: true) unless File.exist?(destination_file)
        end
      end
    end
  end
end
