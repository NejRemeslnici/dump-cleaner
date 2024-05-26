# frozen_string_literal: true

module DumpCleaner
  module FakeData
    class FakeData
      attr_reader :config
      attr_accessor :common_post_processors

      def initialize(config:)
        @data = {}
        @config = config
        @common_post_processors = []
      end

      def get(type)
        @data[type] ||= process_pipeline(type:, pipeline: config.dig(type, "pipeline") || [])
      end

      private

      def process_pipeline(type:, pipeline: [])
        pipeline_processors(pipeline:).reduce(nil) { |data, processor| processor.call(data) }
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
    end
  end
end
