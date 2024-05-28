# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class SelectByteLengthGroup < Base
        def run(orig_value:, id: nil)
          data["#{orig_value.length}-#{orig_value.bytes.length}"]
        end
      end
    end
  end
end
