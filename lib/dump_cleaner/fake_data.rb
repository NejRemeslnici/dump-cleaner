# frozen_string_literal: true

require "singleton"

module DumpCleaner
  class FakeData
    include Singleton

    def initialize
      @data = {}
    end

    def config=(config)
      @config = config
    end

    def get(type)
      @data[type] || begin
        processor_class = @config.dig(type, "processor")
        processor_class = "DumpCleaner::FakeDataProcessors::#{processor_class}" unless processor_class.include?("::")
        p processor_class
        processor = Kernel.const_get(processor_class) rescue ::DumpCleaner::FakeDataProcessors::NilProcessor

        load(type:, file: @config.dig(type, "file"), processor:)
      end
    end

    def load(type:, file:, processor: ::DumpCleaner::FakeDataProcessors::NilProcessor)
      @data[type] = processor.process(YAML.load_file(file))
    end
  end
end
