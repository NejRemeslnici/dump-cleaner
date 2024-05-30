require "singleton"

module DumpCleaner
  module Cleanup
    module Uniqueness
      class MaxRetriesReachedError < StandardError; end

      def repeat_until_unique(type:, orig_value: nil, record: {}, max_retries: 1000, &block)
        n = 0
        result = nil

        loop do
          result = block.call(n)

          break unless result

          unless Ensurer.instance.known?(type:, value: result)
            Ensurer.instance.push(type:, value: result)
            break
          end

          # puts "ID: #{record['id']} type: #{type} orig: #{orig_value} current: #{result} repetition: #{n}"

          if n >= max_retries
            warn "Max retry count #{n} reached for ID:#{record['id']} type:#{type} orig:#{orig_value} current:#{result}"
            raise MaxRetriesReachedError
          end

          n += 1
        end

        result
      end

      class Ensurer
        include Singleton

        def initialize
          clear
        end

        def clear
          @data = {}
        end

        def known?(type:, value:)
          return false unless @data.key?(type)

          @data[type].include?(value.downcase)
        end

        def push(type:, value:)
          @data[type] ||= Set.new
          @data[type].add(value.downcase)
        end
      end
    end
  end
end
