# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module SourceSteps
      class Inspect
        def run(data, type:, values: 10)
          puts "Inspecting '#{type}' data:"
          print_recursively(Marshal.load(Marshal.dump(data)), values:)
          data
        end

        private

        def print_recursively(data, values: 10, level: 0, has_more: false)
          if data.respond_to?(:take) && data.size > values
            data = data.take(values)
            return print_recursively(data, values:, level: level + 1, has_more: true)
          end

          print "  " * level
          if has_more
            print data.inspect[0..-2]
            puts ", ...]"
          else
            p data
          end
        end
      end
    end
  end
end
