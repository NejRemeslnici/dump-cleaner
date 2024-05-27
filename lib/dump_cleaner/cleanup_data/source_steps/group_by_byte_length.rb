# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module SourceSteps
      class GroupByByteLength
        def run(data, type:, hash: false)
          group_by_lambda = -> { "#{_1.length}-#{_1.bytes.length}" }

          if hash
            new_data = {}
            data.each_key { |key| new_data[key] = data[key].group_by(&group_by_lambda) }
            new_data
          else
            data.group_by(&group_by_lambda)
          end
        end
      end
    end
  end
end
