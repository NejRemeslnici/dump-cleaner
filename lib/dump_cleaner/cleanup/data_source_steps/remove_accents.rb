# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module DataSourceSteps
      class RemoveAccents < Base
        def run(under_keys: [])
          block = lambda do |word|
            word.match?(/^\p{ASCII}+$/) ? word : word.unicode_normalize(:nfd).gsub(/\p{M}/, "")
          end

          step_context.cleanup_data = begin
            if under_keys.any?
              new_data = cleanup_data.dup
              under_keys.each do |key|
                new_data[key] = new_data[key].map(&block)
              end
              new_data
            else
              cleanup_data.map(&block)
            end
          end

          step_context
        end
      end
    end
  end
end
