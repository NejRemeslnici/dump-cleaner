# frozen_string_literal: true

module DumpCleaner
  module FakeData
    class Source
      attr_accessor :common_post_processors

      def initialize
        @data = {}
        @common_post_processors = []
      end

      def get(type, pipeline: [])
        @data[type] ||= process_pipeline(type:, pipeline:)
      end

      private

      def process_pipeline(type:, pipeline: [])
        pipeline_processors(pipeline:).reduce(nil) { |data, processor| processor.call(data) }
      end

      def pipeline_processors(pipeline: [])
        (pipeline + common_post_processors).map do |processor_config|
          lambda do |data|
            Kernel.const_get("DumpCleaner::FakeData::Processors::#{processor_config['step']}")
                  .process(data, *processor_config["params"])
          end
        end
      end
    end
  end
end
