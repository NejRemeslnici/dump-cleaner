# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    class CleaningPhase
      include Uniqueness

      def initialize(config:)
        @config = config
        @workflow_steps = {}
      end

      def clean_value_for(orig_value, type:, cleanup_data:, record: {}, keep_record: false)
        keep_value = keep_record || ((conditions = @config.dig(type, "keep_same_if")) &&
                      Conditions.new(conditions).evaluates_to_true?(record, column_value: orig_value))

        if uniqueness_wanted?(type:)
          repeat_until_unique(type:, record:, orig_value:) do |repetition|
            if keep_value
              DumpCleaner::CleanupData::CleaningSteps::RepetitionSuffix.new(data: cleanup_data, type:, repetition:)
                                                                       .run(orig_value:, record:)
            else
              run_workflow(orig_value, type:, cleanup_data:, record: {}, repetition:)
            end
          end
        else
          keep_value ? orig_value : run_workflow(orig_value, type:, cleanup_data:, record: {})
        end
      end

      private

      def run_workflow(orig_value, type:, cleanup_data:, record: {}, repetition: 0)
        run_steps(orig_value:, type:, cleanup_data:, record:, repetition:,
                  steps: workflow_steps_for(type:, phase_part: :cleaning)) ||
          run_steps(orig_value:, type:, cleanup_data:, record:, repetition:,
                    steps: workflow_steps_for(type:, phase_part: :failure))
      end

      def run_steps(orig_value:, type:, cleanup_data:, record: {}, steps: [], repetition: 0)
        workflow_steps(type:, steps:).reduce(cleanup_data) do |data, step|
          step.call(data:, orig_value:, record:, repetition:)
        end
      end

      def workflow_steps(type:, steps: [])
        cache_key = "#{type}-#{steps.map { _1['step'] }.join('_')}"
        @workflow_steps[cache_key] ||= steps.map do |step_config|
          lambda do |data:, orig_value:, record:, repetition:|
            DumpCleaner::CleanupData::CleaningSteps.const_get(step_config["step"])
                                                   .new(data:, type:, step_config:, repetition:)
                                                   .clean_value_for(orig_value:, record:)
          end
        end
      end

      def workflow_steps_for(type:, phase_part:)
        Array(@config.dig(type, phase_part.to_s))
      end

      def uniqueness_wanted?(type:)
        @config.dig(type, "unique")
      end
    end
  end
end
