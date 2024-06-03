# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class DataSource
      def initialize(config:)
        @config = config
        @workflow = Workflow.new(phase: :data_source)
        @data_cache = {}
      end

      def data_for(type)
        step_context = StepContext.new(type:, cleanup_data: nil)
        @data_cache[type] ||= @workflow.run(step_context, step_configs: @config.steps_for(type, :data_source))
                                       .cleanup_data
      end
    end
  end
end
