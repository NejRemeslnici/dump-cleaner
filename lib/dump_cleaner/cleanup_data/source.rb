# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    class Source
      def initialize
        @data = {}
      end

      def data_for(type, steps: [])
        @data[type] ||= process_steps(type:, steps:)
      end

      private

      def process_steps(type:, steps: [])
        steps_processors(steps:).reduce(nil) { |data, processor| processor.call(data, type) }
      end

      def steps_processors(steps: [])
        steps.map do |processor_config|
          params = (processor_config["params"] || {}).transform_keys(&:to_sym)
          lambda do |data, type|
            Kernel.const_get("DumpCleaner::CleanupData::SourceSteps::#{processor_config['step']}")
                  .process(data, type:, **params)
          end
        end
      end
    end
  end
end
