require "yaml"
require "json"
require "dump_cleaner/tsv_table_anonymizer"

module DumpCleaner
  class Processor
    attr_reader :options

    def initialize(options)
      @options = options
      p @options

      config = YAML.load_file("config/dump_cleaner.yml")
      pp config
    end

    def run
      config["cleanups"].each do |cleanup|
        table = cleanup["table"]
        table_info = table_info(db: cleanup["db"], table:)
        p table_info

        TsvTableAnonymizer.new(table, config:, table_info:).run
      end
    end

    private

    def table_info(db:, table:)
      JSON.parse(File.read("#{source_dump_path}/#{db}@#{table}.json"))
    end

    def config
      @config ||= YAML.load_file(options[:config_file])
    end

    def source_dump_path
      config["source_dump_path"]
    end
  end
end
