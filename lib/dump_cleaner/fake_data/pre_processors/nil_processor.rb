# frozen_string_literal: true

module DumpCleaner
  module FakeData
    module PreProcessors
      class NilProcessor
        def self.process(data)
          data
        end
      end
    end
  end
end
