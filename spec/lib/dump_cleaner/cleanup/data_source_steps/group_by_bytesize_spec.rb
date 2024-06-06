# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::DataSourceSteps::GroupByBytesize do
  let(:log) { DumpCleaner::Log.instance }

  def step_context(type: "some_type", cleanup_data: %w[a b cc dd eee fff yellowish žluťoučký])
    DumpCleaner::Cleanup::StepContext.new(type:, cleanup_data:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns a step_context" do
      expect(cleaner(step_context).run).to be_a(DumpCleaner::Cleanup::StepContext)
    end

    it "returns data grouped by character length and bytesize" do
      expect(cleaner(step_context).run.cleanup_data).to eq({ "1-1" => %w[a b],
                                                             "2-2" => %w[cc dd],
                                                             "3-3" => %w[eee fff],
                                                             "9-9" => %w[yellowish],
                                                             "9-13" => %w[žluťoučký] })
    end

    it "returns data under the given keys grouped by character length and bytesize" do
      step_context = step_context(cleanup_data: { "some_key" => %w[a b cc dd eee fff yellowish žluťoučký],
                                                  "another_key" => %w[foo bar] })

      expect(cleaner(step_context).run(under_keys: ["some_key"]).cleanup_data)
        .to eq({ "some_key" => { "1-1" => %w[a b],
                                 "2-2" => %w[cc dd],
                                 "3-3" => %w[eee fff],
                                 "9-9" => %w[yellowish],
                                 "9-13" => %w[žluťoučký] },
                 "another_key" => %w[foo bar] })
    end

    it "raises an error if under_keys contain keys not present in cleanup_data" do
      step_context = step_context(cleanup_data: { "some_key" => %w[a b cc dd eee fff yellowish žluťoučký],
                                                  "another_key" => %w[foo bar] })

      expect { cleaner(step_context).run(under_keys: ["foo_key"]) }.to raise_error(ArgumentError, /keys not present/)
    end
  end
end
