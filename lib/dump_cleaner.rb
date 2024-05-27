# frozen_string_literal: true

require_relative "dump_cleaner/options"
require_relative "dump_cleaner/processor"
require_relative "dump_cleaner/version"
require_relative "dump_cleaner/cleaners/base_cleaner"
require_relative "dump_cleaner/cleaners/mysql_shell_dump_cleaner"
require_relative "dump_cleaner/cleanup_data/data"
require_relative "dump_cleaner/cleanup_data/source"
require_relative "dump_cleaner/cleanup_data/source_steps/group_by_byte_length"
require_relative "dump_cleaner/cleanup_data/source_steps/load_yaml_file"

module DumpCleaner
  class Error < StandardError; end
  # Your code goes here...
end
