# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    class StepContext
      require "pp"

      include Inspection

      attr_accessor :cleanup_data, :current_value, :repetition
      attr_reader :orig_value, :type, :record

      def initialize(type:, cleanup_data:, orig_value: nil, record: {}, repetition: 0)
        @type = type
        @cleanup_data = cleanup_data
        @orig_value = @current_value = orig_value
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

      def pretty_print(pp)
        { orig_value:, current_value:, type:, record:, repetition:,
          cleanup_data: subset(cleanup_data) }.pretty_print(pp)
      end
    end
  end
end
