# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class DeterministicSample < Base
        def run(id:, orig_value:)
          return unless data

          data[Zlib.crc32("#{id}-#{orig_value}") % data.size]
        end
      end
    end
  end
end
