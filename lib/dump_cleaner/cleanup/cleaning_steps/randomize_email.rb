# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class RandomizeEmail < Base
        def run(orig_value:, record: {})
          mailbox, domain = orig_value.split("@", 2)

          if !mailbox || !domain || mailbox.empty? || domain.empty? || !domain.include?(".")
            warn "ID: #{record['id']} invalid email #{orig_value}" if repetition.zero?
            return nil
          end

          new_mailbox = czech_or_random_word_instead_of(mailbox, record:)

          if data["domains"].include?(domain)
            "#{new_mailbox}@#{domain}"
          else
            tld2, _dot, tld = domain.rpartition(".")
            new_tld2 = czech_or_random_word_instead_of(tld2, record:)
            "#{new_mailbox}@#{new_tld2}.#{tld}"
          end
        end

        private

        def czech_or_random_word_instead_of(word, record:)
          czech_word_instead_of(word, record:) || random_word_instead_of(word, record:)
        end

        def czech_word_instead_of(word, record:)
          data["czech_words"]
            .then { SelectByteLengthGroup.new(data: _1, type:).run(orig_value: word, record:) }
            .then do
            DeterministicSample.new(data: _1, type:, repetition:).run(orig_value: word, record:,
                                                                      uniqueness_strategy: :suffix)
          end
        end

        def random_word_instead_of(word, record:)
          SameLengthRandomString.new_from(self).run(orig_value: word, record:)
        end
      end
    end
  end
end
