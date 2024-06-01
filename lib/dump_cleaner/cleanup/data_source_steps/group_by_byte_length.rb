# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module DataSourceSteps
      class GroupByByteLength < Base
        def run(under_keys: [])
          group_by_lambda = -> { "#{_1.length}-#{_1.bytes.length}" }

          step_context.cleanup_data = begin
            if under_keys.any?
              new_data = cleanup_data.dup
              under_keys.each do |key|
                new_data[key] = new_data[key].group_by(&group_by_lambda)
              end
              new_data
            else
              cleanup_data.group_by(&group_by_lambda)
            end
          end

          step_context
        end
      end
    end
  end
end
