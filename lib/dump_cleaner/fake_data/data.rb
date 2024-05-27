# frozen_string_literal: true

module DumpCleaner
  module FakeData
    class Data
      attr_reader :config
      attr_reader :source

      def initialize(config:)
        @config = config
        @source = Source.new
      end

      def get(type:, value:, id: nil)
        source_data = source.get(type, pipeline: config.dig(type, "source") || [])
        fake_data_pool = source_data["#{value.length}-#{value.bytes.length}"]

        if fake_data_pool
          chosen_fake_data_index = Zlib.crc32(id.to_s) % fake_data_pool.size
          fake_data_pool[chosen_fake_data_index]
        else
          warn "ID #{id}: Cannot find appropriate fake data for '#{value}', using some random string instead."
          ("anonymized #{type} " * 10).slice(0...value.bytes.length)
        end
      end
    end
  end
end
