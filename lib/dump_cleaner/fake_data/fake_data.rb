# frozen_string_literal: true

require "singleton"

module DumpCleaner
  module FakeData
    class FakeData
      include Singleton

      attr_accessor :config, :common_post_processors

      def initialize
        @data = {}
        @common_post_processors = []
      end

      def get(type)
        @data[type] ||= process_pipeline(type:, pipeline: config.dig(type, "pipeline") || [])
      end

      def pipeline_processors(pipeline: [])
        (pipeline + common_post_processors).map do |processor_config|
          processor_class = processor_config["class"].split("_").map(&:capitalize).join

          lambda do |data|
            Kernel.const_get("DumpCleaner::FakeData::Processors::#{processor_class}")
                  .process(data, *processor_config["params"])
          end
        end
      end

      def process_pipeline(type:, pipeline: [])
        processors = pipeline_processors(pipeline:)

        data = nil
        processors.each { data = _1.call(data) }
        data
      end
    end
  end
end
