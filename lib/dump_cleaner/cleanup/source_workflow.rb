# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class SourceWorkflow
      def initialize
        @workflow_steps_cache = {}
      end

      def run(type:, steps:)
        workflow_steps(type:, steps:).reduce(nil) do |data, step|
          step.call(data:, type:)
        end
      end

      private

      def workflow_steps(type:, steps: [])
        @workflow_steps_cache[cache_key(type:, steps:)] ||= steps.map do |step_config|
          params = (step_config["params"] || {}).transform_keys(&:to_sym)
          lambda do |data:, type:|
            DumpCleaner::Cleanup::SourceSteps.const_get(step_config["step"])
                                             .new.run(data, type:, **params)
          end
        end
      end

      def cache_key(type:, steps:)
        "source-#{type}-#{steps.map { _1['step'] }.join('_')}"
      end
    end
  end
end
