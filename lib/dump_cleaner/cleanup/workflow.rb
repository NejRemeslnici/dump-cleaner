# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class Workflow
      def initialize(namespace:)
        @namespace = namespace
        @workflow_steps_cache = {}
      end

      def run(initial_step_context, step_configs:)
        steps(type: initial_step_context.type, step_configs:).reduce(initial_step_context.dup) do |step_context, step|
          step.call(step_context)
        end
      end

      private

      def steps(type:, step_configs:)
        @workflow_steps_cache[cache_key(type:, step_configs:)] ||= step_configs.map do |step_config|
          lambda do |step_context|
            @namespace.const_get(step_config.step).new(step_context).run(**step_config.params)
          end
        end
      end

      def cache_key(type:, step_configs:)
        "#{@namespace}-#{type}-#{step_configs.map(&:step).join('-')}"
      end
    end
  end
end
