# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class GenerateRandomString < Base
        require "random/formatter"

        def run(character_set: :alphanumeric)
          random = Random.new(crc32)

          step_context.current_value = random.alphanumeric(current_value.bytesize, chars: characters(character_set))
          step_context
        end

        private

        def characters(character_set)
          case character_set
          when :alphanumeric
            Random::Formatter::ALPHANUMERIC
          when :alpha
            [*"a".."z", *"A".."Z"]
          when :lowercase
            [*"a".."z"]
          when :uppercase
            [*"A".."Z"]
          when :numeric
            [*"0".."9"]
          else
            character_set
          end
        end
      end
    end
  end
end
