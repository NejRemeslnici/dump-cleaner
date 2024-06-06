# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe DumpCleaner::Cleanup::DataSourceSteps::LoadYamlFile do
  def step_context(type: "some_type", cleanup_data: nil)
    DumpCleaner::Cleanup::StepContext.new(type:, cleanup_data:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns a step_context" do
      Tempfile.create do |file|
        expect(cleaner(step_context).run(file: file.path)).to be_a(DumpCleaner::Cleanup::StepContext)
      end
    end

    it "loads the yaml file content to the cleanup_data" do
      Tempfile.create do |file|
        File.open(file, "w") { |f| f.write(%w[a b c d e qq xx yy].to_yaml) }
        expect(cleaner(step_context).run(file: file.path).cleanup_data).to eq(%w[a b c d e qq xx yy])
      end
    end

    it "loads the yaml file content to a key in the cleanup_data if requested" do
      Tempfile.create do |file|
        File.open(file, "w") { |f| f.write(%w[a b c d e qq xx yy].to_yaml) }
        expect(cleaner(step_context).run(file: file.path, under_key: "key").cleanup_data)
          .to eq({ "key" => %w[a b c d e qq xx yy] })
      end
    end

    it "raises error if file not found" do
      expect { cleaner(step_context).run(file: "non_existant") }.to raise_error(Errno::ENOENT)
    end
  end
end
