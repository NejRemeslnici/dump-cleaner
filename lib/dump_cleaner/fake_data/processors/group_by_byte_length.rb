# frozen_string_literal: true

module DumpCleaner
  module FakeData
    module Processors
      class GroupByByteLength
        def self.process(data)
          data.group_by { _1.bytes.length }
        end
      end
    end
  end
end
