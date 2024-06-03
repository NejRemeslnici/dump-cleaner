# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class Cleaning
      include Uniqueness

      attr_reader :config

      def initialize(config:)
        @cleaning_workflow = Workflow.new(phase: :cleaning)
        @failure_workflow = Workflow.new(phase: :failure)
        @config = config
      end

      def clean_value_for(orig_value, type:, cleanup_data:, column_config:, record: {}, keep_record: false)
        step_context = StepContext.new(orig_value:, type:, cleanup_data:, record:)

        # return orig_value if keep_same conditions are met
        if (keep_record && !config.ignore_keep_same_record_conditions?(type)) ||
           Conditions.evaluate_to_true_in_step?(conditions: config.keep_same_conditions(type), step_context:)
          return orig_value_with_optional_suffix(step_context, column_config:)
        end

        if column_config.unique_column?
          begin
            repeat_until_unique(step_context:) do |repetition|
              step_context.repetition = repetition
              run_workflows(step_context)
            end
          rescue MaxRetriesReachedError
            repeat_until_unique(step_context:) do |repetition|
              step_context.repetition = repetition
              run_failure_workflow(step_context)
            end
          end
        else
          run_workflows(step_context)
        end
      end

      private

      def orig_value_with_optional_suffix(step_context, column_config:)
        if column_config.unique_column?
          repeat_until_unique(step_context:) do |repetition|
            step_context.repetition = repetition
            DumpCleaner::Cleanup::CleaningSteps::AddRepetitionSuffix.new(step_context).run.current_value
          end
        else
          step_context.orig_value
        end
      end

      def run_workflows(step_context)
        run_cleaning_workflow(step_context) || run_failure_workflow(step_context)
      end

      def run_cleaning_workflow(step_context)
        @cleaning_workflow.run(step_context, step_configs: config.steps_for(step_context.type, :cleaning)).current_value
      end

      def run_failure_workflow(step_context)
        step_context.current_value = step_context.orig_value # reset current_value
        @failure_workflow.run(step_context, step_configs: config.steps_for(step_context.type, :failure)).current_value
      end
    end
  end
end
