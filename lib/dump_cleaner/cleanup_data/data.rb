# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    class Data
      attr_reader :config

      def initialize(config:)
        @config = config
        @source_phase = SourcePhase.new(config:)
        @cleaning_phase = CleaningPhase.new(config:)
      end

      def clean(type:, orig_value:, record: {})
        cleanup_data = @source_phase.data_for(type, steps: config.dig(type, "source") || [])

        @cleaning_phase.clean_value_for(orig_value, type:, record:, cleanup_data:)
      end
    end
  end
end
