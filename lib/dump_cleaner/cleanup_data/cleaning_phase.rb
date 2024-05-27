# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    class CleaningPhase
      def initialize(config:)
        @config = config
        @workflow_steps = {}
      end

      def clean_value_for(orig_value, type:, cleanup_data:, id:, steps: nil)
        run_workflow(orig_value:, type:, cleanup_data:, id:,
                     steps: steps || workflow_steps_for(type, cleaning_phase_part: :cleaning)) ||
          run_workflow(orig_value:, type:, cleanup_data:, id:,
                       steps: steps || workflow_steps_for(type, cleaning_phase_part: :failure))
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

      def workflow_steps_for(type, cleaning_phase_part:)
        @config.dig(type, cleaning_phase_part.to_s) || []
      end
    end
  end
end
