# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class CleaningWorkflow
      def initialize
        @workflow_steps_cache = {}
      end

      def run(orig_value:, type:, cleanup_data:, steps:, record: {}, repetition: 0)
        workflow_steps(type:, steps:).reduce(cleanup_data) do |data, step|
          step.call(data:, orig_value:, record:, repetition:)
        end
      end

      private

      def workflow_steps(type:, steps: [])
        @workflow_steps_cache[cache_key(type:, steps:)] ||= steps.map do |step_config|
          lambda do |data:, orig_value:, record:, repetition:|
            DumpCleaner::Cleanup::CleaningSteps.const_get(step_config["step"])
                                               .new(data:, type:, step_config:, repetition:)
                                               .clean_value_for(orig_value:, record:)
          end
        end
      end

      def cache_key(type:, steps:)
        "cleaning-#{type}-#{steps.map { _1['step'] }.join('_')}"
      end
    end
  end
end
