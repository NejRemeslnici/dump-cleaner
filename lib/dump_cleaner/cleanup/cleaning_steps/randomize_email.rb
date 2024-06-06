# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module CleaningSteps
      class RandomizeEmail < Base
        def run(domains_to_keep_data_key: "domains_to_keep", words_data_key: "words")
          validate_params(domains_to_keep_data_key:, words_data_key:)

          mailbox, domain = current_value.split("@", 2)

          if !mailbox || !domain || mailbox.empty? || domain.empty? || !domain.include?(".")
            Log.warn { "Invalid email: type=#{type}, id=#{record['id']}, value=#{current_value}" } if repetition.zero?
            step_context.current_value = nil
            return step_context
          end

          new_mailbox = new_mailbox(mailbox, words: cleanup_data[words_data_key])
          new_domain = new_domain(domain, domains: cleanup_data[domains_to_keep_data_key],
                                          words: cleanup_data[words_data_key])

          step_context.current_value = "#{new_mailbox}@#{new_domain}"
          step_context
        end

        private

        def new_mailbox(mailbox, words:)
          if mailbox !~ /^\.|\.\.|\.$/
            mailbox.split(".").map { dictionary_or_random_word_instead_of(_1, words:) }.join(".")
          else
            dictionary_or_random_word_instead_of(mailbox, words:)
          end
        end

        def new_domain(domain, domains:, words:)
          if domains.include?(domain)
            domain
          else
            tld2, _dot, tld = domain.rpartition(".")
            new_tld2 = dictionary_or_random_word_instead_of(tld2, words:)
            "#{new_tld2}.#{tld}"
          end
        end

        def dictionary_or_random_word_instead_of(word, words:)
          dictionary_word_instead_of(word, words:) || random_word_instead_of(word)
        end

        def dictionary_word_instead_of(word, words:)
          context = StepContext.new_from(step_context, current_value: word, cleanup_data: words)
          context = SelectDataByBytesize.new(context).run
          TakeSample.new(context).run(uniqueness_strategy: :suffix).current_value
        end

        def random_word_instead_of(word)
          GenerateRandomString.new(StepContext.new_from(step_context, current_value: word))
                              .run(character_set: :lowercase).current_value
        end

        def validate_params(domains_to_keep_data_key:, words_data_key:)
          unless cleanup_data.respond_to?(:key) &&
                 cleanup_data.key?(domains_to_keep_data_key) && cleanup_data.key?(words_data_key)
            raise_params_error("The cleanup_data does not contain the dictionary keys
                                \"#{domains_to_keep_data_key}\" and \"#{words_data_key})\"".gsub(/\s+/, " "))
          end
        end
      end
    end
  end
end
