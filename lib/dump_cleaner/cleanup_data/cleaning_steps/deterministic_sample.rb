# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class DeterministicSample < Base
        def run(data, id:, type: nil, orig_value: nil)
          return unless data

          data[Zlib.crc32(id.to_s) % data.size]
        end
      end
    end
  end
end
