# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class FillUpWithString < Base
        include BytesizeHelpers

        def run(string: "anonymized #{type}", padding: " ", strict_bytesize_check: false)
          if strict_bytesize_check && string.bytesize != orig_value.bytesize
            raise "The bytesize of the string must be equal to the bytesize of the original value."
          end

          string = set_to_bytesize(string, bytesize: orig_value.bytesize, padding:)
          AddRepetitionSuffix.new(StepContext.new_from(step_context, current_value: string)).run
        end
      end
    end
  end
end
