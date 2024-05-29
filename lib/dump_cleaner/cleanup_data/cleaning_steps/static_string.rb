# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class StaticString < Base
        def run(orig_value:, record: {}, value:)
          value
        end
      end
    end
  end
end
