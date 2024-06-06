# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::InspectContext do
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
      cleaner = cleaner(step_context)

      block = lambda do
        log.level = :debug
        log.reopen($stdout)
        allow(cleaner.step_context).to receive(:pretty_print).and_call_original
        cleaner.run
      end

      expect(&block).to output(/Inspecting step context/).to_stdout
      expect(cleaner.step_context).to have_received(:pretty_print)
    end
  end
end
