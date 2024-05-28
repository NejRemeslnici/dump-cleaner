# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class SameLengthAnonymizedString < Base
        def run(data, type:, orig_value:, id:, repetition: 0, show_warning: false)
          warn "ID #{id}: Cannot find data for '#{orig_value}', using same-length string instead." if show_warning
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
