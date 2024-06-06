# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module DataSourceSteps
      class GroupByBytesize < Base
        def run(under_keys: [])
          validate_params(under_keys:)

          group_by_lambda = -> { "#{_1.length}-#{_1.bytesize}" }

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

        private

        def validate_params(under_keys:)
          return if under_keys.all? { cleanup_data.key?(_1) }

          raise_params_error("The under_keys param contains keys not present in cleanup_data.")
        end
      end
    end
  end
end
