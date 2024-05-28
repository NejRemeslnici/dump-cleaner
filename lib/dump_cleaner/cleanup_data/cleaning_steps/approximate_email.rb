# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class ApproximateEmail < Base
        require "random/formatter"
        require "zlib"

        def run(data, type:, orig_value:, id:, repetition: 0)
          mailbox, domain = orig_value.downcase.split("@")

          if !mailbox || !domain || mailbox.empty? || domain.empty? || !domain.include?(".")
            warn "invalid email #{orig_value}"
            return nil
          end

          new_mailbox = czech_or_random_word_instead_of(mailbox, data:, repetition:)

          if data["domains"].include?(domain)
            "#{new_mailbox}@#{domain}"
          else
            tld2, _dot, tld = domain.rpartition(".")
            new_tld2 = czech_or_random_word_instead_of(tld2, data:, repetition:)

            # puts "#{new_mailbox}@#{new_tld2}.#{tld}"
            "#{new_mailbox}@#{new_tld2}.#{tld}"
          end
        end

        private

        def czech_or_random_word_instead_of(word, data:, repetition: 0)
          czech_word_instead_of(word, data:, repetition:) || random_word_instead_of(word, repetition:)
        end

        def czech_word_instead_of(word, data:, repetition: 0)
          czech_word = data["czech_words"]
                       .then { SelectByteLengthGroup.new.run(_1, orig_value: word) }
                       .then { DeterministicSample.new.run(_1, id: word) }

          if repetition.zero?
            czech_word
          elsif czech_word.length > repetition.to_s.length
            "#{czech_word[0..-repetition.to_s.length - 1]}#{repetition}"
          end
        end

        def random_word_instead_of(word, repetition: 0)
          random = Random.new(Zlib.crc32(word) + repetition)
          random.alphanumeric(word.bytes.length).downcase
        end
      end
    end
  end
end
