# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::Cleaning do
  def step_context(current_value:)
    DumpCleaner::Cleanup::StepContext.new(type: "some_type", cleanup_data: %w[], orig_value: current_value) # this will also set current_value
  end

  def column_config(unique: false)
    DumpCleaner::Config::CleanupTableColumnConfig.new(name: "column", cleanup_type: "type", unique:)
  end

  def config_double(steps: [], ignore_keep_same_record_conditions: false, keep_same_conditions: [], type: "some_type")
    config_double = instance_double(DumpCleaner::Config)
    allow(config_double).to receive(:steps_for).and_return(steps)
    allow(config_double).to receive(:ignore_keep_same_record_conditions?).with(type)
                                                                         .and_return(ignore_keep_same_record_conditions)
    allow(config_double).to receive(:keep_same_conditions).with(type).and_return(keep_same_conditions)
    config_double
  end

  def cleaning_workflow
    cleaning_workflow = instance_double(DumpCleaner::Cleanup::Workflow)
    expect(DumpCleaner::Cleanup::Workflow).to receive(:new).with(phase: :cleaning).and_return(cleaning_workflow)
    cleaning_workflow
  end

  def failure_workflow
    failure_workflow = instance_double(DumpCleaner::Cleanup::Workflow)
    expect(DumpCleaner::Cleanup::Workflow).to receive(:new).with(phase: :failure).and_return(failure_workflow)
    failure_workflow
  end

  before do
    DumpCleaner::Cleanup::Uniqueness::CaseInsensitiveCache.instance.clear
  end

  describe "#clean_value_for" do
    it "creates an initial step_context and runs the cleaning workflow" do
      expect(cleaning_workflow).to receive(:run).and_return(step_context(current_value: "xyz"))
      failure_workflow

      result = described_class.new(config: config_double).clean_value_for("abc", type: "some_type",
                                                                                 cleanup_data: [], column_config:)
      expect(result).to eq("xyz")
    end

    it "runs also the failure workflow when the cleaning phase returns nil" do
      expect(cleaning_workflow).to receive(:run).and_return(step_context(current_value: nil))
      expect(failure_workflow).to receive(:run).and_return(step_context(current_value: "xyz"))

      result = described_class.new(config: config_double).clean_value_for("abc", type: "some_type",
                                                                                 cleanup_data: [], column_config:)
      expect(result).to eq("xyz")
    end

    it "keeps the original value when keep_same conditions are met" do
      expect(cleaning_workflow).not_to receive(:run)
      expect(failure_workflow).not_to receive(:run)

      keep_same_conditions = [DumpCleaner::Config::ConditionConfig.new(condition: "eq", value: "abc", column: nil)]
      result = described_class.new(config: config_double(keep_same_conditions:))
                              .clean_value_for("abc", type: "some_type", cleanup_data: [], column_config:)
      expect(result).to eq("abc")
    end

    it "but does not keeps the original value when keep_same conditions are not met" do
      expect(cleaning_workflow).to receive(:run).and_return(step_context(current_value: nil))
      expect(failure_workflow).to receive(:run).and_return(step_context(current_value: "xyz"))

      keep_same_conditions = [DumpCleaner::Config::ConditionConfig.new(condition: "eq", value: "foo", column: nil)]
      result = described_class.new(config: config_double(keep_same_conditions:))
                              .clean_value_for("abc", type: "some_type", cleanup_data: [], column_config:)
      expect(result).to eq("xyz")
    end

    context "when keep_record is set to true" do
      it "keeps the original value and runs no workflows" do
        expect(cleaning_workflow).not_to receive(:run)
        expect(failure_workflow).not_to receive(:run)

        result = described_class.new(config: config_double).clean_value_for("abc", type: "some_type", cleanup_data: [],
                                                                                   column_config:, keep_record: true)

        expect(result).to eq("abc")
      end

      it "but does not keep the original value and runs workflows when ignore_keep_same_record_conditions is true" do
        expect(cleaning_workflow).to receive(:run).and_return(step_context(current_value: nil))
        expect(failure_workflow).to receive(:run).and_return(step_context(current_value: "xyz"))

        result = described_class.new(config: config_double(ignore_keep_same_record_conditions: true))
                                .clean_value_for("abc", type: "some_type", cleanup_data: [],
                                                        column_config:, keep_record: true)

        expect(result).to eq("xyz")
      end
    end

    context "when uniqueness desired" do
      it "runs the cleaning workflow repeatedly until a unique value is found" do
        expect(cleaning_workflow).to receive(:run).twice.and_return(step_context(current_value: "def"),
                                                                    step_context(current_value: "xyz"))
        expect(failure_workflow).not_to receive(:run)

        DumpCleaner::Cleanup::Uniqueness::CaseInsensitiveCache.instance.push(type: "some_type", value: "def")

        result = described_class.new(config: config_double)
                                .clean_value_for("abc", type: "some_type", cleanup_data: [],
                                                        column_config: column_config(unique: true))
        expect(result).to eq("xyz")
      end

      it "runs both workflows repeatedly until a unique value is found" do
        expect(cleaning_workflow).to receive(:run).twice.and_return(step_context(current_value: nil))
        expect(failure_workflow).to receive(:run).twice.and_return(step_context(current_value: "def"),
                                                                   step_context(current_value: "xyz"))

        DumpCleaner::Cleanup::Uniqueness::CaseInsensitiveCache.instance.push(type: "some_type", value: "def")

        result = described_class.new(config: config_double)
                                .clean_value_for("abc", type: "some_type", cleanup_data: [],
                                                        column_config: column_config(unique: true))
        expect(result).to eq("xyz")
      end

      it "runs the failure workflow repeatedly until a unique value is found when max retries reached" do
        expect(cleaning_workflow).to receive(:run).at_least(:once).and_return(step_context(current_value: "def"))
        expect(failure_workflow).to receive(:run).twice.and_return(step_context(current_value: "def"),
                                                                   step_context(current_value: "xyz"))

        DumpCleaner::Cleanup::Uniqueness::CaseInsensitiveCache.instance.push(type: "some_type", value: "def")

        result = described_class.new(config: config_double)
                                .clean_value_for("abc", type: "some_type", cleanup_data: [],
                                                        column_config: column_config(unique: true))
        expect(result).to eq("xyz")
      end

      context "when keep_record is set to true" do
        it "adds a suffix to the original value and runs no workflows until a unique value is found" do
          expect(cleaning_workflow).not_to receive(:run)
          expect(failure_workflow).not_to receive(:run)

          DumpCleaner::Cleanup::Uniqueness::CaseInsensitiveCache.instance.push(type: "some_type", value: "abc")

          result = described_class.new(config: config_double)
                                  .clean_value_for("abc", type: "some_type", cleanup_data: [],
                                                          column_config: column_config(unique: true),
                                                          keep_record: true)

          expect(result).to eq("ab1")
        end
      end
    end
  end
end
