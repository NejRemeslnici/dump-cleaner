# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class Base
        require "forwardable"
        require "zlib"

        extend Forwardable

        def_delegators :step_context, :cleanup_data, :current_value, :orig_value, :type, :record, :repetition

        attr_reader :step_context

        def initialize(step_context)
          @step_context = step_context.dup
        end

        def crc32(use_repetition: true)
          value_to_hash = "#{record['id_column']}-#{current_value}"
          value_to_hash += "-#{repetition}" if repetition.positive? && use_repetition
          Zlib.crc32(value_to_hash)
        end

        def raise_params_error(error)
          step = self.class.name.split("::").last
          raise ArgumentError, "Invalid cleanup step params: type=#{type}, step=#{step}: #{error}"
        end
      end
    end
  end
end
