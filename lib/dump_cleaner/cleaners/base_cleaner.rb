# frozen_string_literal: true

module DumpCleaner
  module Cleaners
    class BaseCleaner
      attr_reader :config, :options

      def initialize(config:, options:)
        @config = config
        @options = options
      end

      def pre_cleanup
        # Implement in subclass if needed
      end

      def clean
        raise NotImplementedError
      end

      def post_cleanup
        # Implement in subclass if needed
      end

      def keep_same_record?(record, table_config:)
        return false unless table_config.keep_same_record_conditions

        Conditions.new(table_config.keep_same_record_conditions).evaluate_to_true?(record:)
      end
    end
  end
end
