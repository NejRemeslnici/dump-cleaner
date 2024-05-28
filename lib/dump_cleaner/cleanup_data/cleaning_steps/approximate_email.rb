# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class ApproximateEmail < Base
        def run(orig_value:, record: {})
          mailbox, domain = orig_value.downcase.split("@")

          if !mailbox || !domain || mailbox.empty? || domain.empty? || !domain.include?(".")
            warn "ID: #{record['id']} invalid email #{orig_value}"
            return nil
          end

          new_mailbox = czech_or_random_word_instead_of(mailbox, record:)

          if data["domains"].include?(domain)
            "#{new_mailbox}@#{domain}"
          else
            tld2, _dot, tld = domain.rpartition(".")
            new_tld2 = czech_or_random_word_instead_of(tld2, record:)

            # puts "#{new_mailbox}@#{new_tld2}.#{tld}"
            "#{new_mailbox}@#{new_tld2}.#{tld}"
          end
        end

        private

        def czech_or_random_word_instead_of(word, record:)
          czech_word_instead_of(word, record:) || random_word_instead_of(word)
        end

        def czech_word_instead_of(word, record:)
          data["czech_words"]
            .then { SelectByteLengthGroup.new(data: _1, type:).run(orig_value: word, record:) }
            .then do
            DeterministicSample.new(data: _1, type:, repetition:).run(orig_value: word, record:,
                                                                      repetition_suffix: true)
          end
        end

        def random_word_instead_of(word)
          SameLengthRandomString.new(data:, type:, repetition:).run(orig_value: word)
        end
      end
    end
  end
end
