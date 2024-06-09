# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module Inspection
      def inspect_step_context(step_context, message: "Inspecting step context")
        Log.info { message }
        Log.info { "\n#{step_context.pretty_inspect}" }
      end

      def subset(data, values: 10)
        case data
        when Array
          subset_data = data.take(values)
          subset_data << "+ #{data.size - values} more..." if data.size > values
          subset_data.each_with_index { |element, index| subset_data[index] = subset(element, values:) }
        when Hash
          subset_data = data.take(values).to_h
          subset_data["+ #{data.size - values} more..."] = nil if data.size > values
          subset_data.each_key { |key| subset_data[key] = subset(subset_data[key], values:) }
        else
          subset_data = data
        end

        subset_data
      end

      def truncate(value, to: 30, omission: "…")
        return value.dup if value.length <= to

        length_with_room_for_omission = to - omission.length
        stop = length_with_room_for_omission
        +"#{value[0, stop]}#{omission}"
      end
    end
  end
end
