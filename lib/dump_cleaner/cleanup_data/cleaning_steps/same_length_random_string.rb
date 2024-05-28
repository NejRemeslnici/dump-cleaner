# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class SameLengthRandomString < Base
        require "random/formatter"
        require "zlib"

        def run(orig_value:, record: {})
          random = Random.new(Zlib.crc32(orig_value) + repetition)
          random.alphanumeric(orig_value.bytes.length).downcase
        end
      end
    end
  end
end
