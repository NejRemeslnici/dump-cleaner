# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class SameLengthAnonymizedString
        def self.run(data, type:, orig_value:, id:)
          warn "ID #{id}: Cannot find data for '#{orig_value}', using same length anonymized string instead."
          ("anonymized #{type} " * 10).slice(0...orig_value.bytes.length)
        end
      end
    end
  end
end
