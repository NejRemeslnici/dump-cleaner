# frozen_string_literal: true

module DumpCleaner
  class Options
    require "optparse"

    DEFAULT_OPTIONS = {
      config_file: "config/dump_cleaner.yml"
    }.freeze

    attr_accessor :source_dump_path, :destination_dump_path, :config_file

    def initialize(argv)
      DEFAULT_OPTIONS.each { |k, v| send(:"#{k}=", v) }
      parse(argv)
      validate
    end

    private

    def parse(argv)
      OptionParser.new do |parser|
        parser.banner = "Usage: dump_cleaner -f source_dump -t cleaned_dump [options]"

        parser.on("-f", "--from=SOURCE_DUMP_PATH",
                  "File or directory of the original (source) dump") do |option|
          self.source_dump_path = option
        end
        parser.on("-t", "--to=DESTINATION_DUMP_PATH",
                  "File or directory of the cleaned (destination) dump") do |option|
          self.destination_dump_path = option
        end
        parser.on("-c", "--config=CONFIG_FILE", "Configuration file path") do |option|
          self.config_file = option
        end
      end.parse!(argv)
    end

    def validate
      if !source_dump_path || !destination_dump_path # rubocop:disable Style/GuardClause
        raise ArgumentError, "Missing source or destination dump file or directory,
                              please use -f and -t options. Use -h for help.".gsub(/\s+/, " ")
      end
    end
  end
end
