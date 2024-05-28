# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class DeterministicSample < Base
        def run(orig_value:, record: {})
          return unless data

          data[Zlib.crc32("#{record['id']}-#{orig_value}-#{repetition}") % data.size]
        end
      end
    end
  end
end
