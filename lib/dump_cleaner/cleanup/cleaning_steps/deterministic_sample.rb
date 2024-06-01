# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class DeterministicSample < Base
        def run(uniqueness_strategy: :resample)
          return step_context unless cleanup_data

          uniqueness_strategy = uniqueness_strategy.to_sym
          step_context.current_value =
            if uniqueness_strategy == :suffix
              sample = cleanup_data[crc32(current_value:, record:,
                                          use_repetition: false) % cleanup_data.size]
              RepetitionSuffix.new(StepContext.new_from(step_context, current_value: sample)).run.current_value
            elsif uniqueness_strategy == :resample
              cleanup_data[crc32(current_value:, record:) % cleanup_data.size]
            else
              raise ArgumentError, "Unknown uniqueness strategy: #{uniqueness_strategy}"
            end
          step_context
        end
      end
    end
  end
end
