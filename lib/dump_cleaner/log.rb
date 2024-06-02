module DumpCleaner
  require "logger"

  class Log < ::Logger
    require "singleton"

    include Singleton

    attr_reader :logger

    def initialize
      super($stdout)

      self.level = Logger::INFO
      self.formatter = ->(severity, datetime, _progname, msg) { "#{datetime} #{severity}: #{msg}\n" }
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
