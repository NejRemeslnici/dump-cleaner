# frozen_string_literal: true

module DumpCleaner
  class Processor
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      start_time = Time.now

      cleaner_class = case config.dump_format
                      when "mysql_shell_zst"
                        Cleaners::MysqlShellDumpCleaner
                      else
                        raise Config::ConfigurationError, "Unsupported dump format #{config.dump_format}"
                      end

      Log.debug { "Starting cleanup with #{cleaner_class}…" }
      cleaner = cleaner_class.new(config:, options:)
      cleaner.pre_cleanup
      cleaner.clean
      cleaner.post_cleanup

      diff = Time.now - start_time
      Log.info { "Finished in #{diff.div(60)}m #{(diff % 60).to_i}s." }
    end

    private

    def config
      @config ||= Config.new(options.config_file)
    end
  end
end
