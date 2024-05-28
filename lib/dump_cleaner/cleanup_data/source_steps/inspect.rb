# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module SourceSteps
      class Inspect
        include Inspection

        def run(data, type:, values: 10)
          inspect_data_subset(data, message: "Inspecting '#{type}' data", values:)
          data
        end
      end
    end
  end
end
