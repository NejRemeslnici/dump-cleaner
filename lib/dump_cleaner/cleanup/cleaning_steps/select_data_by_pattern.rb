# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class SelectDataByPattern < Base
        def run(patterns:, default_key: nil)
          step_context.cleanup_data = step_context.cleanup_data[match_key(patterns) || default_key]
          step_context
        end

        private

        def match_key(patterns)
          patterns.find { Regexp.new(_1["pattern"], _1["flags"]).match?(step_context.current_value) }&.fetch("key")
        end
      end
    end
  end
end
