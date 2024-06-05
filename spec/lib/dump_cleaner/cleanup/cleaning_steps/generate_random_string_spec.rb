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

    it "returns a random (deterministic) string from the defined character set" do
      step_context = step_context(orig_value: "abcdef")
      expect(cleaner(step_context).run(characters: [*"a".."z"]).current_value).to eq("ktzfne")
      expect(cleaner(step_context).run(characters: [*"a".."z", *"Č".."ě"]).current_value).to eq("qiĒlyo")
    end
  end
end
