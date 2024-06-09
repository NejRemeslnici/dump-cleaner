# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::Inspection do
  let(:dummy) { Class.new { include DumpCleaner::Cleanup::Inspection }.new }

  def step_context(orig_value: "abc", record: { "id_column" => "123" }, type: "some_type",
                   cleanup_data: %w[a b c d e f g], repetition: 0)
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:, repetition:)
  end

  describe "#inspect_step_context" do
    it "calls pretty_print on the step_context" do
      step_context = step_context()
      expect(step_context).to receive(:pretty_inspect)

      dummy.inspect_step_context(step_context)
    end
  end

  describe "subset" do
    it "returns a subset of an array" do
      expect(dummy.subset(%w[a b c d e f g], values: 3)).to eq(["a", "b", "c", "+ 4 more..."])
    end

    it "returns a subset of a recursive array" do
      expect(dummy.subset([%w[a b c d e f g], %w[a b c d e f g]], values: 3))
        .to eq([["a", "b", "c", "+ 4 more..."], ["a", "b", "c", "+ 4 more..."]])
      expect(dummy.subset([%w[a b c d e f g], %w[a b c d e f g]], values: 1))
        .to eq([["a", "+ 6 more..."], "+ 1 more..."])
    end

    it "returns a subset of a hash" do
      expect(dummy.subset({ a: 1, b: 2, c: 3, d: 4, e: 5 }, values: 3))
        .to eq({ a: 1, b: 2, c: 3, "+ 2 more..." => nil })
    end

    it "returns a subset of a recursive hash" do
      expect(dummy.subset({ aa: { a: 1, b: 2, c: 3, d: 4, e: 5 } }, values: 3))
        .to eq({ aa: { a: 1, b: 2, c: 3, "+ 2 more..." => nil} })
    end
  end

  describe "#truncate" do
    it "truncates a string to the specified length including omission" do
      expect(dummy.truncate("abcdefg", to: 5)).to eq("abcd…")
      expect(dummy.truncate("abcdefg", to: 5, omission: "...")).to eq("ab...")
    end
  end
end
