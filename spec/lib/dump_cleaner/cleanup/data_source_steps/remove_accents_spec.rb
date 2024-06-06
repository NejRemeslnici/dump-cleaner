# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::DataSourceSteps::RemoveAccents do
  def step_context(type: "some_type", cleanup_data: [])
    DumpCleaner::Cleanup::StepContext.new(type:, cleanup_data:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns a step_context" do
      expect(cleaner(step_context).run).to be_a(DumpCleaner::Cleanup::StepContext)
    end

    it "returns the cleanup_data with accents removed from all items" do
      expect(cleaner(step_context(cleanup_data: %w[příliš žluťoučký kůň])).run.cleanup_data)
        .to eq(%w[prilis zlutoucky kun])
    end

    it "returns the cleanup_data with accents removed from all items under the given keys" do
      step_context = step_context(cleanup_data: { "some_key" => %w[příliš žluťoučký kůň],
                                                  "another_key" => %w[příliš žluťoučký kůň] })

      expect(cleaner(step_context).run(under_keys: ["another_key"]).cleanup_data)
        .to eq({ "some_key" => %w[příliš žluťoučký kůň], "another_key" => %w[prilis zlutoucky kun] })
    end
  end
end
