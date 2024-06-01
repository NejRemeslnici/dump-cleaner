# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class SelectByteLengthGroup < Base
        def run
          step_context.cleanup_data = cleanup_data["#{current_value.length}-#{current_value.bytes.length}"] ||
                                      cleanup_data["#{current_value.bytes.length}-#{current_value.bytes.length}"] # used if current_value is accented but data isn't
          step_context
        end
      end
    end
  end
end
