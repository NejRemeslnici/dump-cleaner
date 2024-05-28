# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class SameLengthAnonymizedString < Base
        def run(orig_value:, record: {}, show_warning: false)
          if show_warning
            warn "ID #{record['id']}: Cannot find data for '#{orig_value}', using same-length string instead."
          end

          rotate("anonymized #{type} " * 10, repetition).slice(0...orig_value.bytes.length)
        end

        private

        def rotate(word, repetition)
          word.chars.rotate(repetition).join
        end
      end
    end
  end
end
