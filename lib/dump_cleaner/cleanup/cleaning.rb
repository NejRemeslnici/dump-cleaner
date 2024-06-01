# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class Cleaning
      include Uniqueness

      attr_reader :config

      def initialize(config:)
        @config = config
        @workflow = CleaningWorkflow.new
      end

      def clean_value_for(orig_value, type:, cleanup_data:, column:, record: {}, keep_record: false)
        keep_value = (keep_record && !config.ignore_record_keep_same_conditions?(type)) ||
                     ((conditions = config.keep_same_conditions(type)) &&
                      Conditions.new(conditions).evaluate_to_true?(record, column_value: orig_value))

        step_context = StepContext.new(orig_value:, type:, cleanup_data:, record:)

        if column.unique?
          begin
            repeat_until_unique(step_context:) do |repetition|
              step_context.repetition = repetition

              if keep_value
                DumpCleaner::Cleanup::CleaningSteps::RepetitionSuffix.new(step_context).run.current_value
              else
                run_workflows(step_context)
              end
            end
          rescue MaxRetriesReachedError
            repeat_until_unique(step_context:) do |repetition|
              step_context.repetition = repetition
              run_failure_workflow(step_context)
            end
          end
        else
          keep_value ? orig_value : run_workflows(step_context)
        end
      end

      private

      def run_workflows(step_context)
        run_cleaning_workflow(step_context) || run_failure_workflow(step_context)
      end

      def run_cleaning_workflow(step_context)
        @workflow.run(step_context, step_configs: config.steps_for(step_context.type, :cleaning)).current_value
      end

      def run_failure_workflow(step_context)
        step_context.current_value = step_context.orig_value # reset current_value
        @workflow.run(step_context, step_configs: config.steps_for(step_context.type, :failure)).current_value
      end
    end
  end
end
