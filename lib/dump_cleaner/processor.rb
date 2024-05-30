# frozen_string_literal: true

module DumpCleaner
  class Processor
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      cleaner_class = case config.dump_format
                      when "mysql_shell_zst"
                        Cleaners::MysqlShellDumpCleaner
                      else
                        raise "Unsupported dump format #{config.dump_format}"
                      end

      cleaner = cleaner_class.new(config:, options:)
      cleaner.pre_cleanup
      cleaner.clean
      cleaner.post_cleanup
    end

    private

    def config
      @config ||= Config.new(options.config_file)
    end
  end
end
