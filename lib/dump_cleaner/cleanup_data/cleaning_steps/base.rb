# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class Base
        attr_reader :data, :type, :step_config, :repetition

        def initialize(data:, type:, step_config: {}, repetition: 0)
          @data = data
          @type = type
          @step_config = step_config
          @repetition = repetition
        end

        def self.new_from(step)
          new(data: step.data, type: step.type, step_config: step.step_config, repetition: step.repetition)
        end

        def clean_value_for(orig_value:, record: {})
          params = (@step_config["params"] || {}).transform_keys(&:to_sym)
          run(orig_value:, record:, **params)
        end
      end
    end
  end
end
