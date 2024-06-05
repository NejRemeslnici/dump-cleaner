module DumpCleaner
  module Cleanup
    module Uniqueness
      require "singleton"

      class MaxRetriesReachedError < StandardError; end

      def repeat_until_unique(step_context:, max_retries: 1000, &block)
        n = 0
        result = nil

        loop do
          result = block.call(n)

          break unless result

          if n.positive?
            Log.debug do
              msg = "Uniqueness run:  type=#{step_context.type}, id=#{step_context.record['id']}, "
              msg << "orig_value=#{step_context.orig_value}, current_value=#{result}, repetition=#{n}"
            end
          end

          unless Ensurer.instance.known?(type: step_context.type, value: result)
            Ensurer.instance.push(type: step_context.type, value: result)
            break
          end

          if n >= max_retries
            warning = "Max retry count #{n} reached for ID:#{step_context.record['id']}, type:#{step_context.type}, "
            warning << "orig:#{step_context.orig_value}, current:#{result}"
            Log.warn { warning }
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
