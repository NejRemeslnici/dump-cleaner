# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class SelectByteLengthGroup < Base
        def run(orig_value:, record: {})
          data["#{orig_value.length}-#{orig_value.bytes.length}"] ||
            data["#{orig_value.bytes.length}-#{orig_value.bytes.length}"] # used if orig_value is accented but data isn't
        end
      end
    end
  end
end
