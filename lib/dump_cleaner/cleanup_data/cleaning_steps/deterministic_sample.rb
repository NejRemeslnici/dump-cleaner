# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class DeterministicSample < Base
        def run(orig_value:, record: {}, repetition_suffix: false)
          return unless data

          if repetition_suffix
            sample = data[Zlib.crc32("#{record['id']}-#{orig_value}") % data.size]

            if repetition.zero?
              sample
            elsif sample.length > repetition.to_s.length
              "#{sample[0..-repetition.to_s.length - 1]}#{repetition}"
            end
          else
            data[Zlib.crc32("#{record['id']}-#{orig_value}-#{repetition}") % data.size]
          end
        end
      end
    end
  end
end
