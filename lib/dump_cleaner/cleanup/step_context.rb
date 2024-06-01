# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class StepContext
      attr_accessor :cleanup_data, :current_value
      attr_reader :orig_value, :type, :record, :repetition

      def initialize(orig_value:, type:, cleanup_data:, record: {}, repetition: 0)
        @orig_value = @current_value = orig_value
        @type = type
        @cleanup_data = cleanup_data
        @record = record
        @repetition = repetition
      end

      def self.new_from(step_context, **params)
        context_copy = step_context.dup
        new_context = new(orig_value: params[:orig_value] || context_copy.orig_value,
                          type: params[:type] || context_copy.type,
                          cleanup_data: params[:cleanup_data] || context_copy.cleanup_data,
                          record: params[:record] || context_copy.record,
                          repetition: params[:repetition] || context_copy.repetition)
        new_context.current_value = params[:current_value] || context_copy.current_value
        new_context
      end

      def inspect
        { orig_value:, current_value:, type:, record:, repetition: }.inspect
      end
    end
  end
end
