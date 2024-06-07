# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::Workflow do
  def step_context(orig_value: "abc", record: { "id_column" => "123" }, type: "some_type",
                   cleanup_data: %w[a b c d e f g])
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:)
  end

  describe "#run" do
    it "instantiates the steps for the data_source phase and runs them in order" do
      step_configs = [DumpCleaner::Config::CleanupStepConfig.new(step: "RemoveAccents", params: {}),
                      DumpCleaner::Config::CleanupStepConfig.new(step: "InspectContext", params: {})]

      step1_double = instance_double(DumpCleaner::Cleanup::DataSourceSteps::RemoveAccents)
      allow(DumpCleaner::Cleanup::DataSourceSteps::RemoveAccents).to receive(:new).and_return(step1_double)

      step2_double = instance_double(DumpCleaner::Cleanup::DataSourceSteps::InspectContext)
      allow(DumpCleaner::Cleanup::DataSourceSteps::InspectContext).to receive(:new).and_return(step2_double)

      expect(step1_double).to receive(:run)
      expect(step2_double).to receive(:run)

      described_class.new(phase: :data_source).run(step_context, step_configs:)
    end

    it "instantiates the steps for the cleaning phase and runs them in order" do
      step_configs = [DumpCleaner::Config::CleanupStepConfig.new(step: "GenerateRandomString", params: {}),
                      DumpCleaner::Config::CleanupStepConfig.new(step: "FillUpWithString", params: {})]

      step1_double = instance_double(DumpCleaner::Cleanup::CleaningSteps::GenerateRandomString)
      allow(DumpCleaner::Cleanup::CleaningSteps::GenerateRandomString).to receive(:new).and_return(step1_double)

      step2_double = instance_double(DumpCleaner::Cleanup::CleaningSteps::FillUpWithString)
      allow(DumpCleaner::Cleanup::CleaningSteps::FillUpWithString).to receive(:new).and_return(step2_double)

      expect(step1_double).to receive(:run)
      expect(step2_double).to receive(:run)

      described_class.new(phase: :cleaning).run(step_context, step_configs:)
    end

    it "instantiates the steps for the failure phase and runs them in order" do
      step_configs = [DumpCleaner::Config::CleanupStepConfig.new(step: "GenerateRandomString", params: {})]

      step1_double = instance_double(DumpCleaner::Cleanup::CleaningSteps::GenerateRandomString)
      allow(DumpCleaner::Cleanup::CleaningSteps::GenerateRandomString).to receive(:new).and_return(step1_double)

      expect(step1_double).to receive(:run)

      described_class.new(phase: :failure).run(step_context, step_configs:)
    end

    it "raises an error if the step class is not recognized" do
      step_configs = [DumpCleaner::Config::CleanupStepConfig.new(step: "UnknownStep", params: {})]

      expect { described_class.new(phase: :cleaning).run(step_context, step_configs:) }
        .to raise_error(DumpCleaner::Config::ConfigurationError, /Invalid step UnknownStep/)
    end
  end
end
