# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module Inspection
      private

      def inspect_step_context(step_context, message: "Inspecting step context", values: 10)
        puts "#{message} (first #{values} values):"
        pp step_context
        puts "cleanup_data:"
        pp subset(step_context.cleanup_data, values:)
      end

      def subset(data, values: 10)
        case data
        when Array
          subset_data = data.take(values)
          subset_data << "+ #{data.size - values} more..." if data.size > values
          subset_data.each_with_index { |element, index| subset_data[index] = subset(element, values:) }
        when Hash
          subset_data = data.take(values).to_h
          subset_data["+ #{data.size - values} more..."] = [] if data.size > values
          subset_data.each_key { |key| subset_data[key] = subset(subset_data[key], values:) }
        else
          subset_data = data
        end

        subset_data
      end
    end
  end
end
