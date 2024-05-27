# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    class Cleaning
      def initialize
        @workflow_steps = {}
      end

      def clean_value_for(orig_value, type:, cleanup_data:, id:, steps: [])
        run_workflow(orig_value:, type:, cleanup_data:, id:, steps:)
      end

      private

      def run_workflow(orig_value:, type:, cleanup_data:, id:, steps: [])
        workflow_steps(type:, steps:).reduce(cleanup_data) { |data, step| step.call(data:, type:, orig_value:, id:) }
      end

      def workflow_steps(type:, steps: [])
        cache_key = "#{type}-#{steps.map { _1['step'] }.join('_')}"
        @workflow_steps[cache_key] ||= steps.map do |step_config|
          params = (step_config["params"] || {}).transform_keys(&:to_sym)
          lambda do |data:, type:, orig_value:, id:|
            Kernel.const_get("DumpCleaner::CleanupData::CleaningSteps::#{step_config['step']}")
                  .run(data, type:, orig_value:, id:, **params)
          end
        end
      end
    end
  end
end
