# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class Base
        attr_reader :data, :type, :step_config, :repetition

        def initialize(data:, type:, repetition: 0)
          @data = data
          @type = type
          @repetition = repetition
        end

        def self.new_from(step)
          new(data: step.data, type: step.type, repetition: step.repetition)
        end
      end
    end
  end
end
