# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class RandomizeNumber < Base
        def run(orig_value:, record: {}, max_difference: 1.0)
          random = Random.new(Zlib.crc32(orig_value) + repetition)
          spec = "%0.#{orig_value.scan(/\.(.*)$/).first&.first.to_s.length}f"
          new_value = orig_value.to_f + random.rand(max_difference * 2 * 1_000_000) / 1_000_000 - max_difference
          new_value *= -1 if (orig_value.to_f <=> 0) != (new_value <=> 0) # align sign
          format(spec, new_value)
        end
      end
    end
  end
end
