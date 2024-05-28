# frozen_string_literal: true

module DumpCleaner
  module CleanupData
    module CleaningSteps
      class Base
        include ::DumpCleaner::CleanupData::CleaningSteps::Uniqueness

        def self.run(data, type:, orig_value:, id:, uniqueness_wanted: false, **params)
          if uniqueness_wanted
            new.with_uniqueness_ensured(type:, id:, orig_value:) do |repetition|
              run(data, type:, orig_value:, id:, repetition:, **params)
            end
          else
            new.run(data, type:, orig_value:, id:, **params)
          end
        end
      end
    end
  end
end
