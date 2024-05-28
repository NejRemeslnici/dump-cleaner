# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class RandomizeNumber < Base
        def run(orig_value:, record: {}, max_difference: 1.0)
          random = Random.new(Zlib.crc32(orig_value) + repetition)
          spec = "%0.#{orig_value.scan(/\.(.*)$/).first&.first.to_s.length}f"
          format(spec, orig_value.to_f + random.rand(max_difference * 2 * 1_000_000) / 1_000_000 - max_difference)
        end
      end
    end
  end
end
