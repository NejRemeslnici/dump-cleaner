# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class Inspect < Base
        include Inspection

        def run(orig_value:, record: {}, values: 10)
          inspect_data_subset(data, message: "Inspecting '#{type}' data for '#{orig_value}", values:)
          data
        end
      end
    end
  end
end