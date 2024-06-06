# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::RandomizeFormattedNumber do
  def step_context(orig_value:, record: { "id_column" => "123" }, type: "some_type", cleanup_data: [])
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns a step_context" do
      step_context = step_context(orig_value: "1")
      expect(cleaner(step_context).run(format: '(?<x>\d)')).to be_a(DumpCleaner::Cleanup::StepContext)
    end

    it "raises error if format has no named group 'x'" do
      step_context = step_context(orig_value: "1")
      expect { cleaner(step_context).run(format: '(?<some>\d)') }
        .to raise_error(ArgumentError, /named group starting with 'x'/)
    end

    it "raises error if named groups in the format do not match the whole value" do
      step_context = step_context(orig_value: "12 34")
      expect { cleaner(step_context).run(format: '(?<some>\d{2}) (?<x>\d{2})') }
        .to raise_error(ArgumentError, /whole value/)
    end

    it "raises error if an 'x*' named group matches a non-number" do
      step_context = step_context(orig_value: "12a34")
      expect { cleaner(step_context).run(format: "(?<some>.{2})(?<x>.*)") }
        .to raise_error(ArgumentError, /must match numbers only/)
    end

    it "warns and returns nil if the current value does not match the format" do
      step_context = step_context(orig_value: "123456")

      expect(DumpCleaner::Log).to receive(:warn)
      expect(cleaner(step_context).run(format: '(?<some>\d{2})(?<x1>\d{2})').current_value).to be_nil
    end

    it "returns the current_value number as a string" do
      expect(cleaner(step_context(orig_value: "1")).run(format: '(?<x>\d)').current_value).to be_a(String)
    end

    it "returns a formatted with the same length" do
      step_context = step_context(orig_value: "1234567")
      expect(cleaner(step_context).run(format: '(?<some>\d{1})(?<x>\d{6})').current_value.length).to eq(7)
    end

    it "randomizes the numbers in the 'x*' named captures but not others" do
      step_context = step_context(orig_value: "123456")
      result = cleaner(step_context).run(format: '(?<some>\d{3})(?<x>\d{3})').current_value

      expect(result[0...3]).to eq("123")
      expect(result).not_to eq("123456")
      expect(result.to_i).to be_between(123_000, 123_999)
    end

    it "supports multiple groups named 'x*'" do
      step_context = step_context(orig_value: "123 456 789")
      format = '(?<x1>\d{3})(?<space1> )(?<irrelevant>\d{3})(?<space2> )(?<x3>\d{3})'
      result = cleaner(step_context).run(format:).current_value

      expect(result[0...3]).to match(/\d{3}/)
      expect(result[0...3]).not_to eq("123")
      expect(result[4...7]).to eq("456")
      expect(result[8...11]).to match(/\d{3}/)
      expect(result[8...11]).not_to eq("789")
    end

    it "returns a deterministic random number" do
      result1 = cleaner(step_context(orig_value: "123456")).run(format: '(?<some>\d{3})(?<x1>\d{3})').current_value
      result2 = cleaner(step_context(orig_value: "123456")).run(format: '(?<some>\d{3})(?<x1>\d{3})').current_value
      expect(result1).to eq(result2)

      result3 = cleaner(step_context(orig_value: "654321")).run(format: '(?<some>\d{3})(?<x1>\d{3})').current_value
      result4 = cleaner(step_context(orig_value: "654321")).run(format: '(?<some>\d{3})(?<x1>\d{3})').current_value
      expect(result3).to eq(result4)
      expect(result3).not_to eq(result1)
    end
  end
end
