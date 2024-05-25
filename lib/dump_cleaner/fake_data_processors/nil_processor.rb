# frozen_string_literal: true

module DumpCleaner
  module FakeDataProcessors
    class NilProcessor
      def self.process(data)
        data
      end
    end
  end
end
