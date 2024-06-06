# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::SelectDataByPattern do
  def step_context(orig_value:, record: { "id_column" => "123" }, type: "some_type", repetition: 0,
                   cleanup_data: { "male_names" => %w[Jonah Henry Guido],
                                   "female_names" => %w[Jane Martha Beatrice] })
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:, repetition:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns a step_context" do
      patterns = [{ "pattern" => "[ae]$", "flags" => "i", "key" => "female_names" }]
      expect(cleaner(step_context(orig_value: "a")).run(patterns:, default_key: "male_names"))
        .to be_a(DumpCleaner::Cleanup::StepContext)
    end

    it "selects the data under matched key from cleanup_data" do
      patterns = [{ "pattern" => "[ae]$", "key" => "female_names" }]
      expect(cleaner(step_context(orig_value: "Vivienne")).run(patterns:).cleanup_data).to eq(%w[Jane Martha Beatrice])
    end

    it "selects the data under the first matched key from cleanup_data" do
      patterns = [{ "pattern" => "X$", "key" => "male_names" }, { "pattern" => "[ae]$", "key" => "female_names" }]
      expect(cleaner(step_context(orig_value: "Vivienne")).run(patterns:).cleanup_data).to eq(%w[Jane Martha Beatrice])
    end

    it "supports flags in the regexp pattern" do
      patterns = [{ "pattern" => "[ae]$", "flags" => "i", "key" => "female_names" }]
      expect(cleaner(step_context(orig_value: "GEORGINA")).run(patterns:).cleanup_data).to eq(%w[Jane Martha Beatrice])
    end

    it "selects the data under the default_key from cleanup_data if no pattern matches" do
      patterns = [{ "pattern" => "[ae]$", "key" => "female_names" }]
      expect(cleaner(step_context(orig_value: "Jonathan")).run(patterns:, default_key: "male_names").cleanup_data)
        .to eq(%w[Jonah Henry Guido])
    end

    it "selects empty data from cleanup_data if no pattern matches and no default_key given" do
      patterns = [{ "pattern" => "[ae]$", "key" => "female_names" }]
      expect(cleaner(step_context(orig_value: "Jonathan")).run(patterns:).cleanup_data).to be_nil
    end
  end
end
