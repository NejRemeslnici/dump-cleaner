# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class Base
        require "zlib"

        attr_reader :data, :type, :step_config, :repetition

        def initialize(data:, type:, repetition: 0)
          @data = data
          @type = type
          @repetition = repetition
        end

        def crc32(orig_value:, record:, use_repetition: true)
          value_to_hash = "#{record['id_column']}-#{orig_value}"
          value_to_hash += "-#{repetition}" if use_repetition
          Zlib.crc32(value_to_hash)
        end

        def self.new_from(step)
          new(data: step.data, type: step.type, repetition: step.repetition)
        end
      end
    end
  end
end
