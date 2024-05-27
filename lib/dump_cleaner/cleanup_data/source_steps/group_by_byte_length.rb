# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module SourceSteps
      class GroupByByteLength
        def self.process(data)
          data.group_by { "#{_1.length}-#{_1.bytes.length}" }
        end
      end
    end
  end
end
