# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    class Cleaning
      def clean_value_for(orig_value, type:, id:, source_data:, steps: [])
        process_steps(orig_value:, type:, id:, source_data:, steps:)
      end

      private

      def process_steps(orig_value:, type:, id:, source_data:, steps: [])
        steps(step_configs: steps).reduce(source_data) { |data, step| step.call(data, type, orig_value, id) }
      end

      def steps(step_configs: [])
        step_configs.map do |step_config|
          params = (step_config["params"] || {}).transform_keys(&:to_sym)
          lambda do |data, type, orig_value, id|
            Kernel.const_get("DumpCleaner::CleanupData::CleaningSteps::#{step_config['step']}")
                  .process(data, type:, orig_value:, id:, **params)
          end
        end
      end
    end
  end
end
