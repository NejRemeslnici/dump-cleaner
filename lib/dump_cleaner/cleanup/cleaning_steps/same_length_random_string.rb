# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class SameLengthRandomString < Base
        require "random/formatter"

        def run(orig_value:, record: {})
          random = Random.new(crc32(orig_value:, record:))
          random.alphanumeric(orig_value.bytes.length).downcase
        end
      end
    end
  end
end
