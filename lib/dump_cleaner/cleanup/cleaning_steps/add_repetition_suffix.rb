# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class AddRepetitionSuffix < Base
        def run
          step_context.current_value = if repetition.zero?
                                         current_value
                                       elsif current_value.length > repetition.to_s.length
                                         "#{current_value[0..-repetition.to_s.length - 1]}#{repetition}"
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
