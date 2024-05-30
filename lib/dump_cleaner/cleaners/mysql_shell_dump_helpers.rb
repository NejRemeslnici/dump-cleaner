# frozen_string_literal: true

module DumpCleaner
  module Cleaners
    module MysqlShellDumpHelpers
      def destination_file_for(source_file)
        source_file.sub(options.source_dump_path, options.destination_dump_path)
      end
    end
  end
end
