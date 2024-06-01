# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module DataSourceSteps
      class GroupByByteLength
        def run(data, type:, under_keys: [])
          group_by_lambda = -> { "#{_1.length}-#{_1.bytes.length}" }

          if under_keys.any?
            new_data = {}
            data.each_key do |key|
              new_data[key] = under_keys.include?(key) ? data[key].group_by(&group_by_lambda) : data[key]
            end
            new_data
          else
            data.group_by(&group_by_lambda)
          end
        end
      end
    end
  end
end
