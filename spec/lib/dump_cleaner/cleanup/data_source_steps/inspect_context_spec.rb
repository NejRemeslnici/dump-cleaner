# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::DataSourceSteps::InspectContext do
  let(:log) { DumpCleaner::Log.instance }

  def step_context(orig_value: "abc", record: { "id_column"=>"123" }, type: "some_type",
                   cleanup_data: %w[a b c d e f g], repetition: 0)
    @step_context ||= DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:, repetition:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns a step_context" do
      expect(cleaner(step_context).run).to be_a(DumpCleaner::Cleanup::StepContext)
    end

    it "logs the step context and calls its pretty print" do
      allow(step_context).to receive(:pretty_inspect).and_call_original

      block = lambda do
        log.level = :debug
        log.reopen($stdout)
        cleaner(step_context).run
      end

      expect(&block).to output(/Inspecting step context/).to_stdout
      expect(step_context).to have_received(:pretty_inspect)
    end
  end
end
