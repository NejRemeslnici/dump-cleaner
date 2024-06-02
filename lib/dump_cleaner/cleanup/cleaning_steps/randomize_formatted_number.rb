# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class RandomizeFormattedNumber < Base
        def run(format:)
          regex = Regexp.new("\\A#{format}\\z")

          unless current_value.match?(regex)
            # warn "ID: #{record['id']} invalid formatted number: #{current_value}"
            step_context.current_value = nil
            return step_context
          end

          random = Random.new(crc32(current_value:, record:))

          new_value = String.new
          current_value.match(regex).named_captures.each do |name, capture|
            if name.start_with?("x")
              unless capture.match?(/^\d+$/)
                raise "Invalid regexp for capture #{name} which matched to #{capture}: must match numbers only."
              end

              new_value << random_number(capture.length, random:)
            else
              new_value << capture
            end
          end

          step_context.current_value = new_value
          step_context
        end

        private

        def random_number(digits, random:)
          random.rand(10**digits - 1).to_s.rjust(digits, "0")
        end
      end
    end
  end
end
