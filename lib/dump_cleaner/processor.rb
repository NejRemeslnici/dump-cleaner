# frozen_string_literal: true

require "yaml"
require "json"

module DumpCleaner
  class Processor
    attr_reader :options

    def initialize(options)
      @options = options
      p @options
    end

    def run
      config["cleanups"].each do |cleanup|
        Cleaners::MysqlShellDumpCleaner.new(cleanup:, config:, options:).run
      end

      Cleaners::MysqlShellDumpCleaner.copy_unchanged_files(config:, options:)
    end

    private

    def config
      @config ||= load_config_file(options[:config_file])
    end

    def load_config_file(config_file)
      YAML.load_file(config_file)
    end

    def source_dump_path
      config["source_dump_path"]
    end
  end
end
