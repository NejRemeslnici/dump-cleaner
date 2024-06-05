# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::AddRepetitionSuffix do
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

    it "returns the current_value number as a string" do
      expect(cleaner(step_context(orig_value: "abc")).run.current_value).to be_a(String)
    end

    it "returns the current_value when repetition is 0" do
      expect(cleaner(step_context(orig_value: "abc")).run.current_value).to eq("abc")
    end

    it "replaces the value end with the repetition suffix while preserving byte length" do
      expect(cleaner(step_context(orig_value: "abc", repetition: 12)).run.current_value).to eq("a12")
      expect(cleaner(step_context(orig_value: "abč", repetition: 12)).run.current_value).to eq("ab12") # "č" is 2 bytes
      expect(cleaner(step_context(orig_value: "abč", repetition: 1)).run.current_value).to eq("ab01") # "č" is 2 bytes so the suffix must be padded
    end

    it "replaces the value end with a (deterministic) random string if string is smaller than repetition suffix" do
      expect(cleaner(step_context(orig_value: "abc", repetition: 1234)).run.current_value).to eq("6j9")
    end
  end
end
