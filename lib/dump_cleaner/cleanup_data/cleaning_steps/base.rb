# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class Base
        include Uniqueness

        attr_reader :data, :type, :step_config
        attr_accessor :repetition

        def initialize(data:, type:, step_config: {})
          @data = data
          @type = type
          @step_config = step_config
          @repetition = 0
        end

        def clean_value_for(orig_value:, record: {})
          params = (@step_config["params"] || {}).transform_keys(&:to_sym)

          if uniqueness_wanted?
            with_uniqueness_ensured(type:, record:, orig_value:) do |repetition|
              self.repetition = repetition
              run(orig_value:, record:, **params)
            end
          else
            run(orig_value:, record:, **params)
          end
        end

        private

        def uniqueness_wanted?
          @step_config["unique"].to_s == "true"
        end
      end
    end
  end
end
