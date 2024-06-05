# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class TakeSample < Base
        def run(uniqueness_strategy: :resample)
          return step_context if !cleanup_data || cleanup_data.empty?

          uniqueness_strategy = uniqueness_strategy.to_sym
          step_context.current_value =
            if uniqueness_strategy == :resample
              cleanup_data[crc32 % cleanup_data.size]
            elsif uniqueness_strategy == :suffix
              sample = cleanup_data[crc32(use_repetition: false) % cleanup_data.size]
              AddRepetitionSuffix.new(StepContext.new_from(step_context, current_value: sample)).run.current_value
            else
              raise_params_error("Unknown uniqueness strategy: #{uniqueness_strategy}")
            end
          step_context
        end
      end
    end
  end
end
