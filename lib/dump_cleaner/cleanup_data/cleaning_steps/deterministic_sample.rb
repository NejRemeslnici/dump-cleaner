# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class DeterministicSample
        def self.run(data, type:, orig_value:, id:)
          return unless data

          data[Zlib.crc32(id.to_s) % data.size]
        end
      end
    end
  end
end
