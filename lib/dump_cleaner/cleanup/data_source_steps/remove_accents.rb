# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module DataSourceSteps
      class RemoveAccents
        def run(data, type:, under_keys: [])
          block = -> { _1.unicode_normalize(:nfd).gsub(/\p{M}/, "") }

          if under_keys.any?
            new_data = {}
            data.each_key do |key|
              new_data[key] = under_keys.include?(key) ? data[key].map(&block) : data[key]
            end
            new_data
          else
            data.map(&block)
          end
        end
      end
    end
  end
end
