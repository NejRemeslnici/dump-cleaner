# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module SourceSteps
      class LoadYamlFile
        def run(data, type:, file:, under_key: nil)
          loaded_data = YAML.load_file(file)

          new_data = data.dup
          if under_key
            new_data ||= {}
            new_data[under_key] = loaded_data
            new_data
          else
            loaded_data
          end
        end
      end
    end
  end
end
