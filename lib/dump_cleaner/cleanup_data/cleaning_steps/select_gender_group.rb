# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class SelectGenderGroup < Base
        FEMALE_REGEXPS = {
          "first_name" => /[ae]$/i,
          "last_name" => /(ová|ova|ská)$/i
        }.freeze

        def run(data, type:, orig_value:, id:)
          data[guess_gender(type:, orig_value:)]
        end

        private

        def guess_gender(type:, orig_value:)
          orig_value.match?(FEMALE_REGEXPS[type]) ? "female" : "male"
        end
      end
    end
  end
end
