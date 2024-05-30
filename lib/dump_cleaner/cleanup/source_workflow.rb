# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class SourceWorkflow
      def initialize
        @workflow_steps_cache = {}
      end

      def run(type:, step_configs:)
        steps(type:, step_configs:).reduce(nil) do |data, step|
          step.call(data:)
        end
      end

      private

      def steps(type:, step_configs:)
        @workflow_steps_cache[cache_key(type:, step_configs:)] ||= step_configs.map do |step_config|
          lambda do |data:|
            DumpCleaner::Cleanup::SourceSteps.const_get(step_config.step)
                                             .new.run(data, type:, **step_config.params)
          end
        end
      end

      def cache_key(type:, step_configs:)
        "source-#{type}-#{step_configs.map(&:step).join('_')}"
      end
    end
  end
end
