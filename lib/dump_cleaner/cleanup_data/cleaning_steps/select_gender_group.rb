# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class SelectGenderGroup
        def run(data, type:, orig_value:, id:)
          data[guess_gender(orig_value)]
        end

        private

        def guess_gender(orig_value)
          orig_value.end_with?("a") || orig_value.end_with?("e") ? "female" : "male"
        end
      end
    end
  end
end
