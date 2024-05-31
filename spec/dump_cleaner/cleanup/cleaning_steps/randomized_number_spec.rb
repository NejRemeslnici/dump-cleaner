require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::RandomizedNumber do
  let(:cleaner) { described_class.new(data: [], type: "some_type") }

  describe "#run" do
    it "returns a random number that is within the default range" do
      expect(cleaner.run(orig_value: "1", record: { "id_value" => "123" }).to_f).to be_within(1).of(1)
    end

    it "returns a random number that is within the specified range" do
      expect(cleaner.run(orig_value: "1", record: { "id_value" => "123" }, max_difference: 0.1).to_f)
        .to be_within(0.1).of(1)
    end

    it "returns a deterministic random number" do
      result1 = cleaner.run(orig_value: "1", record: { "id_value" => "123" }, max_difference: 1_000_000)
      result2 = cleaner.run(orig_value: "1", record: { "id_value" => "123" }, max_difference: 1_000_000)
      expect(result1).to eq(result2)

      result3 = cleaner.run(orig_value: "2", record: { "id_value" => "123" }, max_difference: 1_000_000)
      result4 = cleaner.run(orig_value: "2", record: { "id_value" => "123" }, max_difference: 1_000_000)
      expect(result3).to eq(result4)
      expect(result3).not_to eq(result1)
    end

    it "keeps the length of the original number" do
      expect(cleaner.run(orig_value: "123.456", record: { "id_value" => "123" }).length).to be 7
      expect(cleaner.run(orig_value: "-123.456", record: { "id_value" => "123" }).length).to be 8
    end

    it "keeps the sign of the original number" do
      10.times do
        expect(cleaner.run(orig_value: "-1", record: { "id_value" => "123" }, max_difference: 1_000_000).to_f).to be < 0
      end

      10.times do
        expect(cleaner.run(orig_value: "1", record: { "id_value" => "123" }, max_difference: 1_000_000).to_f).to be > 0
      end
    end
  end
end
