# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class SameLengthRandomString < Base
        require "random/formatter"

        def run
          random = Random.new(crc32(current_value:, record:))

          step_context.current_value = random.alphanumeric(current_value.bytes.length).downcase
          step_context
        end
      end
    end
  end
end
