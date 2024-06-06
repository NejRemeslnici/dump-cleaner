# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class SelectDataByBytesize < Base
        def run
          return step_context if !cleanup_data || cleanup_data.empty?

          step_context.cleanup_data = cleanup_data["#{current_value.length}-#{current_value.bytesize}"] ||
                                      cleanup_data["#{current_value.bytesize}-#{current_value.bytesize}"] # used when current_value is accented but data isn't
          step_context
        end
      end
    end
  end
end
