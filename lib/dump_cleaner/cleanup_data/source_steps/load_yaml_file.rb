# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module SourceSteps
      class LoadYamlFile
        def self.run(_data, type:, file:)
          YAML.load_file(file)
        end
      end
    end
  end
end
