# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::GenerateRandomString do
  def step_context(orig_value:, record: { "id_column" => "123" }, type: "some_type", cleanup_data: [], repetition: 0)
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:, repetition:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns a step_context" do
      step_context = step_context(orig_value: "abc")
      expect(cleaner(step_context).run).to be_a(DumpCleaner::Cleanup::StepContext)
    end

    it "returns a random (deterministic) alphanumeric string by default" do
      step_context = step_context(orig_value: "abcdef")
      expect(cleaner(step_context).run.current_value).to eq("UCb7nC")
    end

    it "takes repetition into account" do
      step_context = step_context(orig_value: "abcdef", repetition: 10)
      expect(cleaner(step_context).run.current_value).to eq("H4NcOa")
    end

    it "returns a random (deterministic) alpha string" do
      step_context = step_context(orig_value: "abcdef")
      expect(cleaner(step_context).run(character_set: :alpha).current_value).to eq("KWZqhW")
    end

    it "returns a random (deterministic) uppercase string" do
      step_context = step_context(orig_value: "abcdef")
      expect(cleaner(step_context).run(character_set: :uppercase).current_value).to eq("KTZFNE")
    end

    it "returns a random (deterministic) lowercase string" do
      step_context = step_context(orig_value: "abcdef")
      expect(cleaner(step_context).run(character_set: :lowercase).current_value).to eq("ktzfne")
    end

    it "returns a random (deterministic) numeric string" do
      step_context = step_context(orig_value: "abcdef")
      expect(cleaner(step_context).run(character_set: :numeric).current_value).to eq("883244")
    end

    it "returns a random (deterministic) string from the defined custom character set" do
      step_context = step_context(orig_value: "abcdef")
      expect(cleaner(step_context).run(character_set: [*"a".."z"]).current_value).to eq("ktzfne")
      expect(cleaner(step_context).run(character_set: [*"a".."z", *"Č".."Ň"]).current_value).to eq("mČtņyĎ")
    end
  end
end
