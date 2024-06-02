# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class RandomizeFormattedNumber < Base
        include Inspection

        def run(format:)
          regex = Regexp.new("\\A#{format}\\z")

          unless regex.names.any? { _1.start_with?("x") }
            raise ArgumentError, 'The format has no named group starting with \'x\', e.g. \'(?<x>\d)\')'
          end

          unless current_value.match?(regex)
            if repetition.zero?
              Log.warn { "Invalid value: type=#{type}, id=#{record['id']}, value=#{truncate(current_value)}" }
            end
            step_context.current_value = nil
            return step_context
          end

          random = Random.new(crc32(current_value:, record:))
          new_value = randomize_named_captures(regex:, random:)

          if new_value.length != current_value.length
            raise ArgumentError, "The new value length does not match the original value length.
                                  Do the named groups in the format regexp match the whole value?".gsub(/\s+/, " ")
          end

          step_context.current_value = new_value
          step_context
        end

        private

        def randomize_named_captures(regex:, random:)
          new_value = String.new

          current_value.match(regex).named_captures.each do |name, capture|
            if name.start_with?("x")
              unless capture.match?(/^\d+$/)
                raise ArgumentError,
                      "Invalid regexp for capture '#{name}' which matched to '#{capture}': it must match numbers only."
              end

              new_value << random_number(capture.length, random:)
            else
              new_value << capture
            end
          end

          new_value
        end

        def random_number(digits, random:)
          random.rand(10**digits - 1).to_s.rjust(digits, "0")
        end
      end
    end
  end
end
