# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class Inspect < Base
        include Inspection

        def run(values: 10)
          inspect_step_context(step_context, values:)
          step_context
        end
      end
    end
  end
end
