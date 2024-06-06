# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::SelectDataByBytesize do
  def step_context(orig_value:, record: { "id_column" => "123" }, type: "some_type", repetition: 0,
                   cleanup_data: { "1-1" => %w[a b],
                                   "2-2" => %w[cc dd],
                                   "3-3" => %w[eee fff],
                                   "9-9" => %w[yellowish],
                                   "9-13" => %w[žluťoučký] })
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:, repetition:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns a step_context" do
      expect(cleaner(step_context(orig_value: "a")).run).to be_a(DumpCleaner::Cleanup::StepContext)
    end

    it "returns the group with the current_value length and bytesize in the cleanup_data" do
      expect(cleaner(step_context(orig_value: "a")).run.cleanup_data).to eq(%w[a b])
      expect(cleaner(step_context(orig_value: "c")).run.cleanup_data).to eq(%w[a b])
      expect(cleaner(step_context(orig_value: "landrover")).run.cleanup_data).to eq(%w[yellowish])
      expect(cleaner(step_context(orig_value: "žluťoučký")).run.cleanup_data).to eq(%w[žluťoučký])
      expect(cleaner(step_context(orig_value: "žluťoučcí")).run.cleanup_data).to eq(%w[žluťoučký])
      expect(cleaner(step_context(orig_value: "šejdířčin")).run.cleanup_data).to eq(%w[žluťoučký])
    end

    it "returns the group with the current_value bytesize in the cleanup_data if not found by length and bytesize" do
      expect(cleaner(step_context(orig_value: "ač")).run.cleanup_data).to eq(%w[eee fff])
      expect(cleaner(step_context(orig_value: "přístup")).run.cleanup_data).to eq(%w[yellowish])
    end

    it "returns nil if the group is not found in the cleanup_data" do
      expect(cleaner(step_context(orig_value: "foos")).run.cleanup_data).to be_nil
    end

    it "returns the same step context if cleanup_data is nil or empty" do
      step_context = step_context(orig_value: "foo", cleanup_data: [])
      expect(cleaner(step_context).run).to eq(step_context)
    end
  end
end
