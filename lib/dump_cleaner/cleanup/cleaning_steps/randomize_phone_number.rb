# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class RandomizePhoneNumber < Base
        def run(orig_value:, record: {}, format: '(?<front>\+(?:\d{6}))(?<x>\d{6})')
          regex = Regexp.new("\\A#{format}\\z")

          unless orig_value.match?(regex)
            warn "ID: #{record['id']} invalid phone number: #{orig_value}"
            return
          end

          random = Random.new(crc32(orig_value:, record:))

          new_value = String.new
          orig_value.match(regex).named_captures.each do |name, capture|
            if name.start_with?("x")
              unless capture.match?(/^\d+$/)
                raise "Invalid regexp for capture #{name} which matched to #{capture}: must match numbers only."
              end

              new_value << random_number(capture.length, random:)
            else
              new_value << capture
            end
          end

          new_value
        end

        private

        def random_number(digits, random:)
          random.rand(10**digits - 1).to_s.rjust(digits, "0")
        end
      end
    end
  end
end
