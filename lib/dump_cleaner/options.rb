module DumpCleaner
  class Options
    require "optparse"

    DEFAULT_OPTIONS = {
      config_file: "config/dump_cleaner.yml"
    }.freeze

    def self.parse(argv)
      options = DEFAULT_OPTIONS.dup

      OptionParser.new do |parser|
        parser.banner = "Usage: dump_cleaner -f source_dump -t cleaned_dump [options]"

        parser.on("-f", "--from=SOURCE_DUMP_PATH",
                  "File or directory of the original (source) dump") do |option|
          options[:source_dump_path] = option
        end
        parser.on("-t", "--to=DESTINATION_DUMP_PATH",
                  "File or directory of the cleaned (destination) dump") do |option|
          options[:destination_dump_path] = option
        end
        parser.on("-c", "--config=CONFIG_FILE", "Configuration file path") do |option|
          options[:config_file] = option
        end
      end.parse!(argv)

      if !options[:source_dump_path] || !options[:destination_dump_path]
        puts "Missing source or destination dump file or directory, please use -f and -t options. Use -h for help."
        exit 1
      end

      options
    end
  end
end
