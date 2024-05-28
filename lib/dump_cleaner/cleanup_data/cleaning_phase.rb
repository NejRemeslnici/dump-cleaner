# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    class CleaningPhase
      def initialize(config:)
        @config = config
        @workflow_steps = {}
      end

      def clean_value_for(orig_value, type:, cleanup_data:, id:)
        run_workflow(orig_value:, type:, cleanup_data:, id:,
                     steps: workflow_steps_for(type, phase_part: :cleaning)) ||
          run_workflow(orig_value:, type:, cleanup_data:, id:,
                       steps: workflow_steps_for(type, phase_part: :failure))
      end

      private

      def run_workflow(orig_value:, type:, cleanup_data:, id:, steps: [])
        workflow_steps(type:, steps:).reduce(cleanup_data) { |data, step| step.call(data:, type:, orig_value:, id:) }
      end

      def workflow_steps(type:, steps: [])
        cache_key = "#{type}-#{steps.map { _1['step'] }.join('_')}"
        @workflow_steps[cache_key] ||= steps.map do |step_config|
          lambda do |data:, type:, orig_value:, id:|
            return orig_value if step_config["ignore"] && orig_value.match?(/(#{step_config['ignore'].join('|')})/)

            DumpCleaner::CleanupData::CleaningSteps.const_get(step_config["step"])
                                                   .new(data:, type:, step_config:)
                                                   .clean_value_for(orig_value:, id:)
          end
        end
      end

      def workflow_steps_for(type, phase_part:)
        uniqueness_wanted = @config.dig(type, "unique")

        Array(@config.dig(type, phase_part.to_s)).each do |step_config|
          # copy some settings from higher level config
          step_config["unique"] = true if uniqueness_wanted
        end
      end
    end
  end
end
