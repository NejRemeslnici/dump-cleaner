# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class SourcePhase
      def initialize(config:)
        @config = config
        @data = {}
      end

      def data_for(type, steps: [])
        @data[type] ||= run_workflow(type:, steps:)
      end

      private

      def run_workflow(type:, steps: [])
        workflow_steps(steps:).reduce(nil) { |data, step| step.call(data:, type:) }
      end

      def workflow_steps(steps: [])
        steps.map do |step_config|
          params = (step_config["params"] || {}).transform_keys(&:to_sym)
          lambda do |data:, type:|
            DumpCleaner::Cleanup::SourceSteps.const_get(step_config['step'])
                                                 .new.run(data, type:, **params)
          end
        end
      end
    end
  end
end
