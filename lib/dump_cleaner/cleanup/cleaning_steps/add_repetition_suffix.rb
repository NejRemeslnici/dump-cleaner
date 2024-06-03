# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class AddRepetitionSuffix < Base
        include BytesizeHelpers

        def run
          step_context.current_value = if repetition.zero?
                                         current_value
                                       elsif current_value.bytesize > repetition.to_s.bytesize
                                         replace_suffix(current_value, suffix: repetition.to_s, padding: "0")
                                       else
                                         SameLengthRandomString.new(StepContext.new_from(step_context))
                                                               .run.current_value
                                       end
          step_context
        end
      end
    end
  end
end
