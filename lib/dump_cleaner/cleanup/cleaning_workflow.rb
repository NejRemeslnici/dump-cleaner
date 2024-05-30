# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class CleaningWorkflow
      def initialize
        @workflow_steps_cache = {}
      end

      def run(orig_value:, type:, cleanup_data:, step_configs:, record: {}, repetition: 0)
        steps(type:, step_configs:).reduce(cleanup_data) do |data, step|
          step.call(data:, orig_value:, record:, repetition:)
        end
      end

      private

      def steps(type:, step_configs:)
        @workflow_steps_cache[cache_key(type:, step_configs:)] ||= step_configs.map do |step_config|
          lambda do |data:, orig_value:, record:, repetition:|
            DumpCleaner::Cleanup::CleaningSteps.const_get(step_config.step)
                                               .new(data:, type:, repetition:)
                                               .run(orig_value:, record:, **step_config.params)
          end
        end
      end

      def cache_key(type:, step_configs:)
        "cleaning-#{type}-#{step_configs.map(&:step).join('_')}"
      end
    end
  end
end
