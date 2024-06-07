# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Options do
  describe "#initialize" do
    it "parses the options" do
      options = described_class.new(["-f", "source", "-t", "dest", "-c", "config.yml"])

      expect(options.source_dump_path).to eq("source")
      expect(options.destination_dump_path).to eq("dest")
      expect(options.config_file).to eq("config.yml")
    end

    it "merges passed-in options with the default options" do
      options = described_class.new(["-f", "source", "-t", "dest"])

      expect(options.source_dump_path).to eq("source")
      expect(options.destination_dump_path).to eq("dest")
      expect(options.config_file).to eq("config/dump_cleaner.yml")
    end

    it "validates the options" do
      expect { described_class.new(["-f", "source"]) }.to raise_error(ArgumentError, /Missing source or destination/)
      expect { described_class.new(["-t", "dest"]) }.to raise_error(ArgumentError, /Missing source or destination/)
      expect { described_class.new(["-t"]) }.to raise_error(OptionParser::MissingArgument)
      expect { described_class.new([]) }.to raise_error(ArgumentError, /Missing source or destination/)
    end
  end
end
