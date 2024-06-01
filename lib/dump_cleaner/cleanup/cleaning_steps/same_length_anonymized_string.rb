# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class SameLengthAnonymizedString < Base
        def run
          value = ("anonymized #{type} " * 100).slice(0...current_value.bytes.length)
          RepetitionSuffix.new(StepContext.new_from(step_context, current_value: value)).run
        end
      end
    end
  end
end
