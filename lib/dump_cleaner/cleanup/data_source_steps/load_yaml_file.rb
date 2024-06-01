# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module DataSourceSteps
      class LoadYamlFile < Base
        def run(file:, under_key: nil)
          loaded_data = YAML.load_file(file)

          step_context.cleanup_data = if under_key
                                        new_data ||= cleanup_data || {}
                                        new_data[under_key] = loaded_data
                                        new_data
                                      else
                                        loaded_data
                                      end
          step_context
        end
      end
    end
  end
end
