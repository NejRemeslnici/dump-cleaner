# frozen_string_literal: true

require "singleton"

module DumpCleaner
  module FakeData
    class FakeData
      include Singleton

      attr_accessor :config, :pre_processors

      def initialize
        @data = {}
        @pre_processors = []
      end

      def get(type)
        @data[type] ||= load(type:, file: @config.dig(type, "file"), processors: all_pre_processors(type:))
      end

      def all_pre_processors(type:)
        pre_processors = self.pre_processors.dup

        pre_processor_classes = config.dig(type, "pre_processors")
        return pre_processors unless pre_processor_classes

        pre_processor_classes.map! { "DumpCleaner::FakeData::PreProcessors::#{_1}" unless _1.include?("::") }
        pre_processor_classes.each { pre_processors << Kernel.const_get(_1) }
        pre_processors
      end

      def load(type:, file:, processors: [])
        @data[type] ||= begin
          data = YAML.load_file(file)
          processors.each { data = _1.process(data) }
          data
        end
      end
    end
  end
end
