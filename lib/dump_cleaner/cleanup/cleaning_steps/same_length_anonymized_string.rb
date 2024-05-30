# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class SameLengthAnonymizedString < Base
        def run(orig_value:, record: {})
          value = ("anonymized #{type} " * 100).slice(0...orig_value.bytes.length)
          RepetitionSuffix.new_from(self).run(orig_value: value, record:)
        end
      end
    end
  end
end
