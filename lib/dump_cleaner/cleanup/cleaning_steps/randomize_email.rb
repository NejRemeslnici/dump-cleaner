# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class RandomizeEmail < Base
        def run
          mailbox, domain = current_value.split("@", 2)

          if !mailbox || !domain || mailbox.empty? || domain.empty? || !domain.include?(".")
            Log.warn { "Invalid email: id: #{record['id']}, value: #{current_value}" } if repetition.zero?
            step_context.current_value = nil
            return step_context
          end

          new_mailbox = czech_or_random_word_instead_of(mailbox)

          step_context.current_value = if cleanup_data["domains"].include?(domain)
                                         "#{new_mailbox}@#{domain}"
                                       else
                                         tld2, _dot, tld = domain.rpartition(".")
                                         new_tld2 = czech_or_random_word_instead_of(tld2)
                                         "#{new_mailbox}@#{new_tld2}.#{tld}"
                                       end

          step_context
        end

        private

        def czech_or_random_word_instead_of(word)
          czech_word_instead_of(word) || random_word_instead_of(word)
        end

        def czech_word_instead_of(word)
          context = StepContext.new_from(step_context, current_value: word, cleanup_data: cleanup_data["czech_words"])
          context = SelectByteLengthGroup.new(context).run
          DeterministicSample.new(context).run(uniqueness_strategy: :suffix).current_value
        end

        def random_word_instead_of(word)
          SameLengthRandomString.new(StepContext.new_from(step_context, current_value: word)).run.current_value
        end
      end
    end
  end
end
