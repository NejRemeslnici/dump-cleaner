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
          unless instance_of?(DumpCleaner::Cleanup::CleaningSteps::Inspect)
            # puts "Initializing #{self.class.name}"
            # Inspect.new(step_context).run
          end
          @step_context = step_context
        end

        def crc32(current_value:, record:, use_repetition: true)
          value_to_hash = "#{record['id_column']}-#{current_value}"
          value_to_hash += "-#{repetition}" if use_repetition
          Zlib.crc32(value_to_hash)
        end
      end
    end
  end
end
