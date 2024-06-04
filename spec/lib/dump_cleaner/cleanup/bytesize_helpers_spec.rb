require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::BytesizeHelpers do
  let(:dummy) { Class.new { include DumpCleaner::Cleanup::BytesizeHelpers }.new }

  describe "#truncate_to_bytesize" do
    it "returns the string if it is shorter than the max_bytesize" do
      expect(dummy.truncate_to_bytesize("abc", max_bytesize: 4)).to eq("abc")
    end

    it "truncates the string to the max_bytesize" do
      expect(dummy.truncate_to_bytesize("abcd", max_bytesize: 2)).to eq("ab")
    end

    it "truncates a multibyte string to the max_bytesize" do
      expect(dummy.truncate_to_bytesize("αβγπ", max_bytesize: 4)).to eq("αβ")
    end

    it "adjusts a multibyte string with padding if needed" do
      expect(dummy.truncate_to_bytesize("αβγπ", max_bytesize: 5)).to eq("αβ ")
      expect(dummy.truncate_to_bytesize("€", max_bytesize: 2, padding: "E")).to eq("EE")
    end

    it "raises an error if the padding is a multibyte character" do
      expect do
        dummy.truncate_to_bytesize("αβγπ", max_bytesize: 4, padding: "π")
      end.to raise_error(ArgumentError, /single-byte/)
    end
  end

  describe "#set_to_bytesize" do
    it "returns the string if it is already the correct bytesize" do
      expect(dummy.set_to_bytesize("abc", bytesize: 3)).to eq("abc")
      expect(dummy.set_to_bytesize("abαβ", bytesize: 6)).to eq("abαβ")
    end

    it "truncates the string if it is longer than desired" do
      expect(dummy.set_to_bytesize("abc", bytesize: 2)).to eq("ab")
      expect(dummy.set_to_bytesize("abαβ", bytesize: 4)).to eq("abα")
    end

    it "adjusts the truncated string with padding if needed" do
      expect(dummy.set_to_bytesize("abαβ", bytesize: 5)).to eq("abα ")
    end

    it "repeats the string with padding if it is shorter than desired" do
      expect(dummy.set_to_bytesize("abc", bytesize: 7)).to eq("abc abc")
      expect(dummy.set_to_bytesize("abc", bytesize: 5)).to eq("abc a")
      expect(dummy.set_to_bytesize("αβγ", bytesize: 13)).to eq("αβγ αβγ")
      expect(dummy.set_to_bytesize("αβγ", bytesize: 12)).to eq("αβγ αβ ")

      expect(dummy.set_to_bytesize("αβ€", bytesize: 15)).to eq("αβ€ αβ€")
      expect(dummy.set_to_bytesize("αβ€", bytesize: 14)).to eq("αβ€ αβ  ")
      expect(dummy.set_to_bytesize("αβ€", bytesize: 13)).to eq("αβ€ αβ ")
      expect(dummy.set_to_bytesize("αβ€", bytesize: 12)).to eq("αβ€ αβ")
    end

    it "raises an error if the padding is a multibyte character" do
      expect do
        dummy.set_to_bytesize("αβγπ", bytesize: 4, padding: "π")
      end.to raise_error(ArgumentError, /single-byte/)
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
      expect { dummy.replace_suffix("12€", suffix: "10", padding: "π") }.to raise_error(ArgumentError, /single-byte/)
    end
  end
end
