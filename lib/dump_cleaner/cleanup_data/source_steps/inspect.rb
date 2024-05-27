# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module SourceSteps
      require "pp"

      class Inspect
        def run(data, type:, values: 10)
          puts "Inspecting '#{type}' data:"
          PP.singleline_pp data
          data
        end
      end
    end
  end
end
