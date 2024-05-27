# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module SourceSteps
      class LoadYamlFile
        def self.process(_data, type:, file:)
          YAML.load_file(file)
        end
      end
    end
  end
end
