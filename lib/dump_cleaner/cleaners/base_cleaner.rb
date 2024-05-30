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
    end
  end
end
