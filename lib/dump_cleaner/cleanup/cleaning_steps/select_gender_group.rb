# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class SelectGenderGroup < Base
        FEMALE_REGEXPS = {
          "first_name" => /[ae]$/i,
          "last_name" => /(ová|ova|ská)$/i
        }.freeze

        def run
          step_context.cleanup_data = step_context.cleanup_data[guess_gender]
          step_context
        end

        private

        def guess_gender
          current_value.match?(FEMALE_REGEXPS[type]) ? "female" : "male"
        end
      end
    end
  end
end
