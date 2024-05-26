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
      cleaner_class = case config.dig("dump", "format")
                      when "mysql_shell_zst"
                        Cleaners::MysqlShellDumpCleaner
                      else
                        raise "Unsupported dump format #{config.dig('dump', 'format')}"
                      end

      begin
        cleaner = cleaner_class.new(config:, options:)
        cleaner.pre_cleanup
        cleaner.clean
        cleaner.post_cleanup
      rescue StandardError => e
        raise "Error while cleaning dump", e
      end
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
