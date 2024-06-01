# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class CleaningWorkflow
      def initialize
        @workflow_steps_cache = {}
      end

      def run(orig_value:, type:, cleanup_data:, step_configs:, record: {}, repetition: 0)
        initial_step_context = StepContext.new(orig_value:, type:, cleanup_data:, record:, repetition:)
        steps(type:, step_configs:).reduce(initial_step_context) do |step_context, step|
          step.call(step_context)
        end
      end

      private

      def steps(type:, step_configs:)
        @workflow_steps_cache[cache_key(type:, step_configs:)] ||= step_configs.map do |step_config|
          lambda do |step_context|
            DumpCleaner::Cleanup::CleaningSteps.const_get(step_config.step).new(step_context).run(**step_config.params)
          end
        end
      end

      def cache_key(type:, step_configs:)
        "cleaning-#{type}-#{step_configs.map(&:step).join('_')}"
      end
    end
  end
end
