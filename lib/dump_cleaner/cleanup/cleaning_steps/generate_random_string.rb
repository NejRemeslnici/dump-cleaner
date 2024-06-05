# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class GenerateRandomString < Base
        require "random/formatter"

        def run(characters: nil)
          random = Random.new(crc32)

          step_context.current_value = random.alphanumeric(current_value.bytesize,
                                                           chars: characters || Random::Formatter::ALPHANUMERIC)
          step_context
        end
      end
    end
  end
end
