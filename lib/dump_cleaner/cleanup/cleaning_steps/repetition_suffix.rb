# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class RepetitionSuffix < Base
        def run(orig_value:, record: {})
          if repetition.zero?
            orig_value
          elsif orig_value.length > repetition.to_s.length
            "#{orig_value[0..-repetition.to_s.length - 1]}#{repetition}"
          else
            SameLengthRandomString.new_from(self).run(orig_value:, record:)
          end
        end
      end
    end
  end
end
