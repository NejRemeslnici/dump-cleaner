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

        if column.unique?
          begin
            repeat_until_unique(type:, record:, orig_value:) do |repetition|
              if keep_value
                step_context = StepContext.new(orig_value:, type:, cleanup_data:, record:, repetition:)
                DumpCleaner::Cleanup::CleaningSteps::RepetitionSuffix.new(step_context).run.current_value
              else
                run_workflows(orig_value:, type:, cleanup_data:, record:, repetition:)
              end
            end
          rescue MaxRetriesReachedError
            repeat_until_unique(type:, record:, orig_value:) do |repetition|
              run_failure_workflow(orig_value:, type:, cleanup_data:, record:, repetition:)
            end
          end
        else
          keep_value ? orig_value : run_workflows(orig_value:, type:, cleanup_data:, record:)
        end
      end

      private

      def run_workflows(orig_value:, type:, cleanup_data:, record: {}, repetition: 0)
        run_cleaning_workflow(orig_value:, type:, cleanup_data:, record:, repetition:) ||
          run_failure_workflow(orig_value:, type:, cleanup_data:, record:, repetition:)
      end

      def run_cleaning_workflow(orig_value:, type:, cleanup_data:, record: {}, repetition: 0)
        @workflow.run(orig_value:, type:, cleanup_data:, record:, repetition:,
                      step_configs: config.steps_for(type, :cleaning)).current_value
      end

      def run_failure_workflow(orig_value:, type:, cleanup_data:, record: {}, repetition: 0)
        @workflow.run(orig_value:, type:, cleanup_data:, record:, repetition:,
                      step_configs: config.steps_for(type, :failure)).current_value
      end
    end
  end
end
