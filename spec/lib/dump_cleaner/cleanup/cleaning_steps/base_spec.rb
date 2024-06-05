# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::Base do
  def step_context(orig_value:, record: { "id_column" => "123" }, type: "some_type", cleanup_data: [], repetition: 0)
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:, repetition:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#crc32" do
    it "constructs a CRC32 checksum from the ID, current value when repetition is 0" do
      step_context = step_context(orig_value: "abcd")
      expect(cleaner(step_context).crc32).to eq(Zlib.crc32("123-abcd"))
    end

    it "constructs a CRC32 checksum from the ID, current value and positive repetition" do
      step_context = step_context(orig_value: "abcd", repetition: 10)
      expect(cleaner(step_context).crc32).to eq(Zlib.crc32("123-abcd-10"))
    end

    it "constructs a CRC32 checksum from the ID, current value and no repetition if requested" do
      step_context = step_context(orig_value: "abcd", repetition: 10)
      expect(cleaner(step_context).crc32(use_repetition: false)).to eq(Zlib.crc32("123-abcd"))
    end
  end
end
