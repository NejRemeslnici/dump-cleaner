# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class RandomizePhoneNumber < Base
        def run(orig_value:, record: {})
          unless orig_value.length >= 9
            warn "ID: #{record['id']} invalid phone number: #{orig_value}"
            return
          end

          prefix = orig_value.slice(0...orig_value.length - 6)
          random = Random.new(Zlib.crc32(orig_value) + repetition)
          "#{prefix}#{format('%06d', random.rand(999_999))}"
        end
      end
    end
  end
end
