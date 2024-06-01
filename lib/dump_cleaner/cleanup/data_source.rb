# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class DataSource
      def initialize(config:)
        @config = config
        @workflow = SourceWorkflow.new
        @data_cache = {}
      end

      def data_for(type)
        @data_cache[type] ||= @workflow.run(type:, step_configs: @config.steps_for(type, :data_source))
      end
    end
  end
end
