# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module SourceSteps
      class LoadYamlFile
        def run(data, type:, file:, key: nil)
          YAML.load_file(file)
        end
      end
    end
  end
end
