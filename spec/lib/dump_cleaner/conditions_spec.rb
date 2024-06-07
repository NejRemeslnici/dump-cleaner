# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Conditions do
  describe "#evaluate_to_true?" do
    it "returns false if no conditions defined" do
      expect(described_class.new([]).evaluate_to_true?(record: {})).to be_falsey
    end

    it "supports a 'eq' condition" do
      conditions = [DumpCleaner::Config::ConditionConfig.new(column: "column1", value: "123", condition: "eq")]

      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "123" })).to be_truthy
      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "234" })).to be_falsey
    end

    it "supports a 'ne' condition" do
      conditions = [DumpCleaner::Config::ConditionConfig.new(column: "column1", value: "123", condition: "ne")]

      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "123" })).to be_falsey
      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "234" })).to be_truthy
    end

    it "supports a 'start_with' condition" do
      conditions = [DumpCleaner::Config::ConditionConfig.new(column: "column1", value: "abc", condition: "start_with")]

      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "abcdef" })).to be_truthy
      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "ghi" })).to be_falsey
    end

    it "supports a 'end_with' condition" do
      conditions = [DumpCleaner::Config::ConditionConfig.new(column: "column1", value: "xyz", condition: "end_with")]

      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "uvwxyz" })).to be_truthy
      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "ghi" })).to be_falsey
    end

    it "supports a 'non_zero' condition" do
      conditions = [DumpCleaner::Config::ConditionConfig.new(column: "column1", condition: "non_zero", value: nil)]

      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "12" })).to be_truthy
      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "0" })).to be_falsey
    end

    it "returns true if any of the conditions evaluates to true" do
      conditions = [DumpCleaner::Config::ConditionConfig.new(column: "column1", value: "123", condition: "eq"),
                    DumpCleaner::Config::ConditionConfig.new(column: "column2", value: "234", condition: "eq")]

      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "123", "column2" => "234" }))
        .to be_truthy
      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "123", "column2" => "789" }))
        .to be_truthy
      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "abc", "column2" => "234" }))
        .to be_truthy
      expect(described_class.new(conditions).evaluate_to_true?(record: { "column1" => "abc", "column2" => "def" }))
        .to be_falsey
    end

    it "evaluates against column_value if no column specified" do
      conditions = [DumpCleaner::Config::ConditionConfig.new(column: nil, value: "123", condition: "eq")]

      expect(described_class.new(conditions).evaluate_to_true?(record: {}, column_value: "123")).to be_truthy
      expect(described_class.new(conditions).evaluate_to_true?(record: {}, column_value: "456")).to be_falsey
    end
  end

  describe ".evaluate_to_true_in_step?" do
    it "uses step_context to evaluate conditions against" do
      step_context = DumpCleaner::Cleanup::StepContext.new(orig_value: "abc", record: {}, type: "some_type",
                                                           cleanup_data: [])
      conditions = [DumpCleaner::Config::ConditionConfig.new(condition: "eq", value: "abc", column: nil)]
      expect(described_class.evaluate_to_true_in_step?(conditions:, step_context:)).to be_truthy
    end
  end
end
