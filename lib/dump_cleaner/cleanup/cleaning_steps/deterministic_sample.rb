# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class DeterministicSample < Base
        def run(orig_value:, record: {}, uniqueness_strategy: :resample)
          return unless data

          uniqueness_strategy = uniqueness_strategy.to_sym
          if uniqueness_strategy == :suffix
            sample = data[crc32(orig_value:, record:, use_repetition: false) % data.size]
            RepetitionSuffix.new_from(self).run(orig_value: sample, record:)
          elsif uniqueness_strategy == :resample
            data[crc32(orig_value:, record:) % data.size]
          else
            raise ArgumentError, "Unknown uniqueness strategy: #{uniqueness_strategy}"
          end
        end
      end
    end
  end
end
