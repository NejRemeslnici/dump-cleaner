# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class RandomizeNumber < Base
        def run(difference_within: 1.0)
          random = Random.new(crc32(current_value:, record:))

          new_value = current_value.to_f + random.rand(difference_within.to_f * 2) - difference_within.to_f

          # keep sign to keep string length (warning: this skews the distribution of the random numbers)
          if (current_value.strip[0] == "-") && new_value.positive? ||
             (current_value.strip[0] != "-") && new_value.negative?
            new_value *= -1
          end

          decimal_places = current_value.split(".")[1].to_s.length
          epsilon = 10**-decimal_places
          clamped_value = new_value.clamp(current_value.to_f - difference_within + epsilon,
                                          current_value.to_f + difference_within - epsilon)

          step_context.current_value = format("%0#{current_value.length}.#{decimal_places}f", clamped_value)
          step_context
        end
      end
    end
  end
end
