# frozen_string_literal: true

require_relative "dump_cleaner/options"
require_relative "dump_cleaner/processor"
require_relative "dump_cleaner/version"
require_relative "dump_cleaner/cleaners/base_cleaner"
require_relative "dump_cleaner/cleaners/mysql_shell_dump_cleaner"
require_relative "dump_cleaner/fake_data/fake_data"
require_relative "dump_cleaner/fake_data/processors/bytes_length_grouper"
require_relative "dump_cleaner/fake_data/processors/yaml_file_loader"

module DumpCleaner
  class Error < StandardError; end
  # Your code goes here...
end
