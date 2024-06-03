require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::BytesizeHelpers do
  let(:dummy) { Class.new { include DumpCleaner::Cleanup::BytesizeHelpers }.new }

  describe "#truncate_to_bytes" do
    it "returns the string if it is shorter than the max_bytes" do
      expect(dummy.truncate_to_bytes("abc", max_bytes: 4)).to eq("abc")
    end

    it "truncates the string to the max_bytes" do
      expect(dummy.truncate_to_bytes("abcd", max_bytes: 2)).to eq("ab")
    end

    it "truncates a multibyte string to the max_bytes" do
      expect(dummy.truncate_to_bytes("ěščř", max_bytes: 4)).to eq("ěš")
    end

    it "truncates a multibyte string to less than max_bytes if that would produce invalid UTF character" do
      expect(dummy.truncate_to_bytes("ěščř", max_bytes: 5)).to eq("ěš")
      expect(dummy.truncate_to_bytes("€", max_bytes: 2)).to eq("")
    end
  end

  describe "#replace_suffix" do
    it "replaces the end of the string by the given suffix" do
      expect(dummy.replace_suffix("abc", suffix: "d")).to eq("abd")
    end

    it "replaces the end of the string by the given suffix (multibyte strings)" do
      expect(dummy.replace_suffix("ěšč", suffix: "ř")).to eq("ěšř")
      expect(dummy.replace_suffix("ěšč", suffix: "ř").bytesize).to eq("ěšč".bytesize)
    end

    it "pads the suffix by the given padding if needed (if we split a multibyte character)" do
      expect(dummy.replace_suffix("ěšč", suffix: "1", padding: "0")).to eq("ěš01")
      expect(dummy.replace_suffix("ěšč", suffix: "1", padding: "0").bytesize).to eq("ěšč".bytesize)

      expect(dummy.replace_suffix("cost 12€", suffix: "1", padding: "0")).to eq("cost 12001")
      expect(dummy.replace_suffix("cost 12€", suffix: "1", padding: "0").bytesize).to eq("cost 12€".bytesize)
    end
  end
end
