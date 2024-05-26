# frozen_string_literal: true

require "singleton"

module DumpCleaner
  class FakeData
    include Singleton

    attr_accessor :config

    def initialize
      @data = {}
    end

    def get(type)
      @data[type] ||= begin
        processor_class = @config.dig(type, "processor")
        processor_class = "DumpCleaner::FakeDataProcessors::#{processor_class}" unless processor_class.include?("::")
        p processor_class
        processor = begin
          Kernel.const_get(processor_class)
        rescue StandardError
          ::DumpCleaner::FakeDataProcessors::NilProcessor
        end

        load(type:, file: @config.dig(type, "file"), processor:)
      end
    end

    def load(type:, file:, processor: ::DumpCleaner::FakeDataProcessors::NilProcessor)
      @data[type] = processor.process(YAML.load_file(file))
    end
  end
end
