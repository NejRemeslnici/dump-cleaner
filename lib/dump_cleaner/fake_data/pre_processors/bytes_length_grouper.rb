# frozen_string_literal: true

module DumpCleaner
  module FakeData
    module PreProcessors
      class BytesLengthGrouper
        def self.process(data)
          data.group_by { _1.bytes.length }
        end
      end
    end
  end
end
