# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class RandomizedNumber < Base
        def run(orig_value:, record: {}, difference_within: 1.0)
          random = Random.new(crc32(orig_value:, record:))

          new_value = orig_value.to_f + random.rand(difference_within.to_f * 2) - difference_within.to_f

          # keep sign to keep string length (warning: this skews the distribution of the random numbers)
          if (orig_value.strip[0] == "-") && new_value.positive? || (orig_value.strip[0] != "-") && new_value.negative?
            new_value *= -1
          end

          decimal_places = orig_value.split(".")[1].to_s.length
          epsilon = 10**-decimal_places
          clamped_value = new_value.clamp(orig_value.to_f - difference_within + epsilon,
                                          orig_value.to_f + difference_within - epsilon)

          format("%0#{orig_value.length}.#{decimal_places}f", clamped_value)
        end
      end
    end
  end
end
