# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::RandomizeNumber do
  def step_context(orig_value:, record: { "id_value" => "123" }, type: "some_type", cleanup_data: [])
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns the step_context" do
      step_context = step_context(orig_value: "1")
      expect(cleaner(step_context).run).to eq(step_context)
    end

    it "returns the current_value number as a string" do
      expect(cleaner(step_context(orig_value: "1")).run.current_value).to be_a(String)
    end

    it "returns a number with the same length" do
      expect(cleaner(step_context(orig_value: "123.456")).run.current_value.length).to eq(7)
      expect(cleaner(step_context(orig_value: "-123.456")).run.current_value.length).to eq(8)
    end

    it "returns a number with the same number of decimal places" do
      expect(cleaner(step_context(orig_value: "123.456")).run.current_value.split(".")[1].to_s.length).to eq(3)
      expect(cleaner(step_context(orig_value: "-123.4")).run.current_value.split(".")[1].to_s.length).to eq(1)
      expect(cleaner(step_context(orig_value: "-123")).run.current_value.split(".")[1].to_s.length).to eq(0)
    end

    it "returns a random number that is within the default range" do
      expect(cleaner(step_context(orig_value: "10.0")).run.current_value.to_f).to be_within(1).of(10)
    end

    it "returns a random number that is within the specified range" do
      expect(cleaner(step_context(orig_value: "1.0")).run(difference_within: 0.2).current_value.to_f)
        .to be_within(0.2).of(1)
    end

    it "clamps the number when difference too small" do
      expect(cleaner(step_context(orig_value: "1000")).run(difference_within: 1.0).current_value.to_f).to eq(1000)
      expect(cleaner(step_context(orig_value: "10.0")).run(difference_within: 0.1).current_value.to_f).to eq(10)
    end

    it "returns a deterministic random number" do
      result1 = cleaner(step_context(orig_value: "1")).run(difference_within: 1_000_000).current_value
      result2 = cleaner(step_context(orig_value: "1")).run(difference_within: 1_000_000).current_value
      expect(result1).to eq(result2)

      result3 = cleaner(step_context(orig_value: "2")).run(difference_within: 1_000_000).current_value
      result4 = cleaner(step_context(orig_value: "2")).run(difference_within: 1_000_000).current_value
      expect(result3).to eq(result4)
      expect(result3).not_to eq(result1)
    end

    it "keeps the sign of the original number by default" do
      (-10..-1).each do |i|
        expect(cleaner(step_context(orig_value: i.to_s)).run(difference_within: 1_000_000).current_value.to_f).to be < 0
      end

      (1..10).each do |i|
        expect(cleaner(step_context(orig_value: i.to_s)).run(difference_within: 1_000_000).current_value.to_f).to be > 0
      end
    end
  end
end
