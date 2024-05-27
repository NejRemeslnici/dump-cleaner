# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    class Data
      attr_reader :config
      attr_reader :source

      def initialize(config:)
        @config = config
        @source = Source.new
      end

      def get(type:, orig_value:, id: nil)
        source_data = source.data_for(type, steps: config.dig(type, "source") || [])
        cleaning_steps = config.dig(type, "cleaning") || []
        cleanup_data_pool = source_data["#{orig_value.length}-#{orig_value.bytes.length}"]

        if cleanup_data_pool
          chosen_cleanup_data_index = Zlib.crc32(id.to_s) % cleanup_data_pool.size
          cleanup_data_pool[chosen_cleanup_data_index]
        else
          warn "ID #{id}: Cannot find appropriate fake data for '#{orig_value}', using some random string instead."
          ("anonymized #{type} " * 10).slice(0...orig_value.bytes.length)
        end
      end
    end
  end
end
