# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class InspectContext < Base
        include Inspection

        def run
          inspect_step_context(step_context)
          step_context
        end
      end
    end
  end
end
