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
      expect(dummy.truncate_to_bytes("αβγπ", max_bytes: 4)).to eq("αβ")
    end

    it "truncates a multibyte string to less than max_bytes if that would produce invalid UTF character" do
      expect(dummy.truncate_to_bytes("αβγπ", max_bytes: 5)).to eq("αβ")
      expect(dummy.truncate_to_bytes("€", max_bytes: 2)).to eq("")
    end
  end

  describe "#replace_suffix" do
    it "replaces the end of the string by the given suffix" do
      expect(dummy.replace_suffix("abc", suffix: "d")).to eq("abd")
    end

    it "replaces the end of the string by the given suffix (multibyte strings)" do
      expect(dummy.replace_suffix("αβγ", suffix: "π")).to eq("αβπ")
      expect(dummy.replace_suffix("αβγ", suffix: "π").bytesize).to eq("αβγ".bytesize)
    end

    it "pads the suffix by the given padding if needed (if we split a multibyte character)" do
      expect(dummy.replace_suffix("αβγ", suffix: "1", padding: "0")).to eq("αβ01")
      expect(dummy.replace_suffix("αβγ", suffix: "1", padding: "0").bytesize).to eq("αβγ".bytesize)

      expect(dummy.replace_suffix("cost 12€", suffix: "1", padding: "0")).to eq("cost 12001")
      expect(dummy.replace_suffix("cost 12€", suffix: "1", padding: "0").bytesize).to eq("cost 12€".bytesize)
    end

    it "raises an error if the padding is a multibyte character" do
      expect { dummy.replace_suffix("12€", suffix: "10", padding: "π") }.to raise_error(ArgumentError, /multi-byte/)
    end
  end
end
