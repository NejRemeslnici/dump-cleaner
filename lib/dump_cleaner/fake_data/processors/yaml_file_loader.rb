# frozen_string_literal: true

module DumpCleaner
  module FakeData
    module Processors
      class YamlFileLoader
        def self.process(_data, file)
          YAML.load_file(file)
        end
      end
    end
  end
end
