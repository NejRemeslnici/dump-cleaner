# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class SelectByteLengthGroup
        def self.run(data, type:, orig_value:, id:)
          data["#{orig_value.length}-#{orig_value.bytes.length}"]
        end
      end
    end
  end
end
