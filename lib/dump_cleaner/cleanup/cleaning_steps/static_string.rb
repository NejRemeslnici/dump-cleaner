# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class StaticString < Base
        def run(value:)
          step_context.current_value = value
          step_context
        end
      end
    end
  end
end
