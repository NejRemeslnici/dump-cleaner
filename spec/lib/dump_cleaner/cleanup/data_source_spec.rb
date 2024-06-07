# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::DataSource do
  describe "#data_for" do
    it "creates an initial step_context and runs the workflow" do
      workflow_double = instance_double(DumpCleaner::Cleanup::Workflow)
      expect(DumpCleaner::Cleanup::Workflow).to receive(:new).and_return(workflow_double)

      step_context = DumpCleaner::Cleanup::StepContext.new(type: "some_type", cleanup_data: %w[a b c])
      expect(workflow_double).to receive(:run).and_return(step_context)

      config_double = instance_double(DumpCleaner::Config)
      allow(config_double).to receive(:steps_for).and_return([])

      result = described_class.new(config: config_double).data_for("some_type")
      expect(result).to eq(%w[a b c])
    end
  end
end
