# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::FillUpWithString do
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

    context "with custom string provided" do
      it "returns the string if bytesize equal" do
        step_context = step_context(orig_value: "abcdef")
        expect(cleaner(step_context).run(string: "uvwxyz").current_value).to eq("uvwxyz")
      end

      it "returns the string truncated if too long" do
        step_context = step_context(orig_value: "abc")
        expect(cleaner(step_context).run(string: "efghij").current_value).to eq("efg")
      end

      it "returns the string repeated (separated by spaces) if too short" do
        step_context = step_context(orig_value: "abcdefg")
        expect(cleaner(step_context).run(string: "xyz").current_value).to eq("xyz xyz")
      end

      it "returns the string repeated (separated by custom padding) if too short" do
        step_context = step_context(orig_value: "abcdefg")
        expect(cleaner(step_context).run(string: "xyz", padding: "-").current_value).to eq("xyz-xyz")
      end
    end

    context "with default string" do
      it "returns the 'anonymized type' string if bytesize equal" do
        step_context = step_context(orig_value: "some equally long st")
        expect(cleaner(step_context).run.current_value).to eq("anonymized some_type")
      end

      it "returns the 'anonymized type' string truncated if too long" do
        step_context = step_context(orig_value: "abc")
        expect(cleaner(step_context).run.current_value).to eq("ano")
      end

      it "returns the 'anonymized type' string repeated (separated by spaces) if too short" do
        step_context = step_context(orig_value: "some very long string and still even longer")
        expect(cleaner(step_context).run.current_value).to eq("anonymized some_type anonymized some_type a")
      end

      it "returns the 'anonymized type' string repeated (separated by custom padding) if too short" do
        step_context = step_context(orig_value: "some very long string and still even longer")
        expect(cleaner(step_context).run(padding: "-").current_value)
          .to eq("anonymized some_type-anonymized some_type-a")
      end
    end

    it "raises error if byte sizes don't match and strict check requested" do
      step_context = step_context(orig_value: "abcdefg")
      expect do
        cleaner(step_context).run(string: "xyz", strict_bytesize_check: true).current_value
      end.to raise_error(/must be equal/)
    end
  end
end
