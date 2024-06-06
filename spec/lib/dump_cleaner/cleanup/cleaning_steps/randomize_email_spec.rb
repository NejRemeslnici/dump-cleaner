# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Cleanup::CleaningSteps::RandomizeEmail do
  def step_context(orig_value:, record: { "id_column" => "123" }, type: "some_type",
                   cleanup_data: { "domains_to_keep" => %w[gmail.com],
                                   "words" => { "7-7" => %w[orderly context] } })
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:)
  end

  def cleaner(step_context)
    described_class.new(step_context)
  end

  describe "#run" do
    it "returns a step_context" do
      expect(cleaner(step_context(orig_value: "someone@gmail.com")).run).to be_a(DumpCleaner::Cleanup::StepContext)
    end

    it "returns nil value for invalid mail address" do
      expect(cleaner(step_context(orig_value: "invalidmail")).run.current_value).to be_nil
    end

    it "returns mail with (deterministic random) dictionary mailbox and same domain if the domain is in keep list" do
      expect(cleaner(step_context(orig_value: "someone@gmail.com")).run.current_value).to eq("orderly@gmail.com")
      expect(cleaner(step_context(orig_value: "someone@gmail.com")).run.current_value).to eq("orderly@gmail.com")
    end

    it "returns mail with (deterministic random) dictionary mailbox and domain while keeping tld" do
      expect(cleaner(step_context(orig_value: "someone@liberal.cz")).run.current_value).to eq("orderly@context.cz")
      expect(cleaner(step_context(orig_value: "someone@liberal.cz")).run.current_value).to eq("orderly@context.cz")
    end

    it "returns mail with (deterministically) generated random mailbox if not found in dictionary" do
      expect(cleaner(step_context(orig_value: "foo@liberal.cz")).run.current_value).to eq("hvg@context.cz")
      expect(cleaner(step_context(orig_value: "foo@liberal.cz")).run.current_value).to eq("hvg@context.cz")
    end

    it "returns mail with (deterministically) generated random mailbox and domain if not found in dictionary" do
      expect(cleaner(step_context(orig_value: "foo@bar.cz")).run.current_value).to eq("hvg@sgb.cz")
      expect(cleaner(step_context(orig_value: "foo@bar.cz")).run.current_value).to eq("hvg@sgb.cz")
    end

    it "keeps dots in mailbox and randomizes the parts separately" do
      expect(cleaner(step_context(orig_value: "someone.dustful@gmail.com")).run.current_value)
        .to eq("orderly.context@gmail.com")
      expect(cleaner(step_context(orig_value: "someone.foo@gmail.com")).run.current_value)
        .to eq("orderly.hvg@gmail.com")
      expect(cleaner(step_context(orig_value: "foo.bar@gmail.com")).run.current_value)
        .to eq("hvg.sgb@gmail.com")
      expect(cleaner(step_context(orig_value: "foo.bar@baz.cz")).run.current_value)
        .to eq("hvg.sgb@kgi.cz")
    end
  end
end
