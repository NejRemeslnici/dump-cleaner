# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::Uniqueness do
  let(:dummy) { Class.new { include DumpCleaner::Cleanup::Uniqueness }.new }

  def step_context(orig_value: "abc", record: { "id_column" => "123" }, type: "some_type",
                   cleanup_data: %w[a b c d e f g], repetition: 0)
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:, repetition:)
  end

  before do
    DumpCleaner::Cleanup::Uniqueness::CaseInsensitiveCache.instance.clear
  end

  describe "#repeat_until_unique" do
    it "calls the block repeatedly until the result is unique" do
      result = dummy.repeat_until_unique(step_context:) do |repetition|
        repetition < 3 ? "a" : "b"
      end
      expect(result).to eq("a")

      result = dummy.repeat_until_unique(step_context:) do |repetition|
        repetition < 3 ? "a" : "b"
      end
      expect(result).to eq("b")
    end

    it "checks for uniqueness case-insensitively" do
      result = dummy.repeat_until_unique(step_context:) do |repetition|
        repetition < 3 ? "a" : "b"
      end
      expect(result).to eq("a")

      result = dummy.repeat_until_unique(step_context:) do |repetition|
        repetition < 3 ? "A" : "b"
      end
      expect(result).to eq("b")
    end

    it "checks uniqueness individually for the step_context type" do
      result = dummy.repeat_until_unique(step_context:) do |repetition|
        repetition < 3 ? "a" : "b"
      end
      expect(result).to eq("a")

      result = dummy.repeat_until_unique(step_context: step_context(type: "another_type")) do |repetition|
        repetition < 3 ? "a" : "b"
      end
      expect(result).to eq("a")
    end

    it "raises an error if maximum retries reached" do
      dummy.repeat_until_unique(step_context:) do |repetition|
        repetition < 3 ? "a" : "b"
      end

      expect do
        dummy.repeat_until_unique(step_context:, max_retries: 2) do |repetition|
          repetition < 3 ? "a" : "b"
        end
      end.to raise_error(DumpCleaner::Cleanup::Uniqueness::MaxRetriesReachedError)
    end
  end
end
