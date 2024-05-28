require "singleton"

module DumpCleaner
  module CleanupData
    module CleaningSteps
      module Uniqueness
        def with_uniqueness_ensured(type:, id:, orig_value:, &block)
          n = 0
          result = nil

          loop do
            result = block.call(n)

            break unless result

            unless Ensurer.instance.known?(type:, value: result)
              Ensurer.instance.push(type:, value: result)
              break
            end

            if n >= 1000
              warn "Max retry count reached for #{type} #{id} #{orig_value}"
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
            @data.dig(type, value) == 1
          end

          def push(type:, value:)
            @data[type] ||= {}
            @data[type][value] = 1
          end
        end
      end
    end
  end
end
