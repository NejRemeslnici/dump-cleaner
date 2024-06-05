# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::TakeSample do
  def step_context(orig_value:, record: { "id_column" => "123" }, type: "some_type",
                   cleanup_data: %w[abc def ghi jkl], repetition: 0)
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:, repetition:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns the step_context without changing current_value when data is empty" do
      step_context = step_context(orig_value: "1", cleanup_data: [])
      result = cleaner(step_context).run
      expect(result).to eq(step_context)
      expect(result.current_value).to eq("1")
    end

    it "returns the step_context when data is present" do
      step_context = step_context(orig_value: "1")
      expect(cleaner(step_context).run).to eq(step_context)
    end

    it "returns the current_value number as a string" do
      expect(cleaner(step_context(orig_value: "1")).run.current_value).to be_a(String)
    end

    context "when uniqueness strategy is :resample" do
      it "takes a sample from cleanup data (no repetition)" do
        expect(cleaner(step_context(orig_value: "1", repetition: 0)).run.current_value).to eq("def")
      end

      it "takes a different sample from cleanup data (with repetition)" do
        expect(cleaner(step_context(orig_value: "1", repetition: 2)).run.current_value).to eq("jkl")
      end
    end

    context "when uniqueness strategy is :suffix" do
      it "takes a sample from cleanup data (no repetition)" do
        step_context = step_context(orig_value: "1", repetition: 0)
        expect(cleaner(step_context).run(uniqueness_strategy: :suffix).current_value).to eq("def")
      end

      it "takes the same sample from cleanup data and adds a repetition suffix (with repetition)" do
        step_context = step_context(orig_value: "1", repetition: 2)
        expect(cleaner(step_context).run(uniqueness_strategy: :suffix).current_value).to eq("de2")
      end
    end

    it "raises error when uniqueness strategy is unknown" do
      expect { cleaner(step_context(orig_value: "1")).run(uniqueness_strategy: :foo) }
        .to raise_error(ArgumentError, /Unknown uniqueness strategy/)
    end
  end
end
