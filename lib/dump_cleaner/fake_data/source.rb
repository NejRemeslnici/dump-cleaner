# frozen_string_literal: true

module DumpCleaner
  module FakeData
    class Source
      def initialize
        @data = {}
      end

      def get(type, pipeline: [])
        @data[type] ||= process_pipeline(type:, pipeline:)
      end

      private

      def process_pipeline(type:, pipeline: [])
        pipeline_processors(pipeline:).reduce(nil) { |data, processor| processor.call(data) }
      end

      def pipeline_processors(pipeline: [])
        pipeline.map do |processor_config|
          params = (processor_config["params"] || {}).transform_keys(&:to_sym)
          lambda do |data|
            Kernel.const_get("DumpCleaner::FakeData::Processors::#{processor_config['step']}").process(data, **params)
          end
        end
      end
    end
  end
end
