# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    class Data
      attr_reader :config
      attr_reader :source
      attr_reader :cleaning

      def initialize(config:)
        @config = config
        @source = Source.new
        @cleaning = Cleaning.new
      end

      def get(type:, orig_value:, id: nil)
        cleanup_data = source.data_for(type, steps: config.dig(type, "source") || [])
        cleaning.clean_value_for(orig_value, type:, id:, cleanup_data:, steps: config.dig(type, "cleaning") || []) ||
          cleaning.clean_value_for(orig_value, type:, id:, cleanup_data:, steps: config.dig(type, "failure") || [])
      end
    end
  end
end
