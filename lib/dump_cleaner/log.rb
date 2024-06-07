module DumpCleaner
  require "logger"

  class Log < ::Logger
    require "singleton"

    include Singleton

    attr_reader :logger

    def initialize
      super($stdout)

      init_log_level
      self.formatter = ->(severity, datetime, _progname, msg) { "#{datetime} #{severity}: #{msg}\n" }
    end

    def init_log_level
      self.level = Logger::INFO
    end

    def self.debug(&block)
      instance.debug(&block)
    end

    def self.info(&block)
      instance.info(&block)
    end

    def self.warn(&block)
      instance.warn(&block)
    end

    def self.error(&block)
      instance.error(&block)
    end

    def self.fatal(&block)
      instance.fatal(&block)
    end
  end
end
