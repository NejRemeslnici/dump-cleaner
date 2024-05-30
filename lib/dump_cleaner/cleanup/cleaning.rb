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

      def clean_value_for(orig_value, type:, cleanup_data:, record: {}, keep_record: false)
        keep_value = (keep_record && !config.ignore_record_keep_same_conditions?(type)) ||
                     ((conditions = config.keep_same_conditions(type)) &&
                      Conditions.new(conditions).evaluate_to_true?(record, column_value: orig_value))

        if config.uniqueness_wanted?(type)
          begin
            repeat_until_unique(type:, record:, orig_value:) do |repetition|
              if keep_value
                DumpCleaner::Cleanup::CleaningSteps::RepetitionSuffix.new(data: cleanup_data, type:, repetition:)
                                                                     .run(orig_value:, record:)
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
                      step_configs: config.steps_for(type, :cleaning))
      end

      def run_failure_workflow(orig_value:, type:, cleanup_data:, record: {}, repetition: 0)
        @workflow.run(orig_value:, type:, cleanup_data:, record:, repetition:,
                      step_configs: config.steps_for(type, :failure))
      end
    end
  end
end
