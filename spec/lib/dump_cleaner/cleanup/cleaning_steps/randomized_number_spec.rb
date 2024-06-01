require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::RandomizedNumber do
  let(:cleaner) { described_class.new(data: [], type: "some_type") }
  let(:record) { { "id_value" => "123" } }

  describe "#run" do
    it "returns a number as a string" do
      expect(cleaner.run(orig_value: "1", record:)).to be_a(String)
    end

    it "returns a number with the same length" do
      expect(cleaner.run(orig_value: "123.456", record:).length).to eq(7)
      expect(cleaner.run(orig_value: "-123.456", record:).length).to eq(8)
    end

    it "returns a number with the same number of decimal places" do
      expect(cleaner.run(orig_value: "123.456", record:).split(".")[1].to_s.length).to eq(3)
      expect(cleaner.run(orig_value: "-123.4", record:).split(".")[1].to_s.length).to eq(1)
      expect(cleaner.run(orig_value: "-123", record:).split(".")[1].to_s.length).to eq(0)
    end

    it "returns a random number that is within the default range" do
      expect(cleaner.run(orig_value: "10.0", record:).to_f).to be_within(1).of(10)
    end

    it "returns a random number that is within the specified range" do
      expect(cleaner.run(orig_value: "1.0", record:, difference_within: 0.2).to_f).to be_within(0.2).of(1)
    end

    it "clamps the number when difference too small" do
      expect(cleaner.run(orig_value: "1000", record:, difference_within: 1.0).to_f).to eq(1000)
      expect(cleaner.run(orig_value: "10.0", record:, difference_within: 0.1).to_f).to eq(10)
    end

    it "returns a deterministic random number" do
      result1 = cleaner.run(orig_value: "1", record:, difference_within: 1_000_000)
      result2 = cleaner.run(orig_value: "1", record:, difference_within: 1_000_000)
      expect(result1).to eq(result2)

      result3 = cleaner.run(orig_value: "2", record:, difference_within: 1_000_000)
      result4 = cleaner.run(orig_value: "2", record:, difference_within: 1_000_000)
      expect(result3).to eq(result4)
      expect(result3).not_to eq(result1)
    end

    it "keeps the sign of the original number by default" do
      (-10..-1).each do |i|
        expect(cleaner.run(orig_value: i.to_s, record:, difference_within: 1_000_000).to_f).to be < 0
      end

      (1..10).each do |i|
        expect(cleaner.run(orig_value: i.to_s, record:, difference_within: 1_000_000).to_f).to be > 0
      end
    end
  end
end
