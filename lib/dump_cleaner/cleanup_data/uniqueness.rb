require "singleton"

module DumpCleaner
  module CleanupData
    module Uniqueness
      def repeat_until_unique(type:, orig_value: nil, record: {}, max_retries: 100, &block)
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
            result = nil
            break
          end

          n += 1
        end

        result
      end

      class Ensurer
        include Singleton

        def initialize
          @data = {}
        end

        def known?(type:, value:)
          @data.dig(type, value.downcase)
        end

        def push(type:, value:)
          @data[type] ||= {}
          @data[type][value.downcase] = 1
        end
      end
    end
  end
end
