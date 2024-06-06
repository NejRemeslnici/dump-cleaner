# frozen_string_literal: true

RSpec.describe DumpCleaner::Cleanup::StepContext do
  def step_context(orig_value: "abc", record: { "id_column" => "123" }, type: "some_type",
                   cleanup_data: %w[a b c d e f g], repetition: 0)
    DumpCleaner::Cleanup::StepContext.new(orig_value:, record:, type:, cleanup_data:, repetition:)
  end

  describe "#to_h" do
    it "returns the step context as a hash" do
      expect(step_context.to_h).to eq(orig_value: "abc", current_value: "abc", type: "some_type",
                                      record: { "id_column" => "123" }, repetition: 0,
                                      cleanup_data: %w[a b c d e f g])
    end
  end

  describe "#==" do
    it "returns true if the other step_context has the same values" do
      expect(step_context.==(step_context.dup)).to be true
    end

    it "returns true if the other step_context differs in its values" do
      expect(step_context.==(step_context(repetition: 1))).to be false
      expect(step_context.==(step_context(cleanup_data: %w[a b c d e f g h]))).to be false
    end
  end

  describe "#pretty_print" do
    it "returns a pretty-formatted step context state to use in pretty_inspect and pp" do
      output = step_context.pretty_inspect
      expect(output).to include(':orig_value=>"abc"')
      expect(output).to include(':current_value=>"abc"')
      expect(output).to include(':type=>"some_type"')
      expect(output).to include(':record=>{"id_column"=>"123"}')
      expect(output).to include(":repetition=>0")
      expect(output).to include(':cleanup_data=>["a", "b", "c", "d", "e", "f", "g"]')
    end

    it "prints only a subset of the cleanup_data" do
      step_context = step_context(cleanup_data: %w[a b c d e f g h i j k l m n o p q r s t u v w x y z])
      output = step_context.pretty_inspect
      expect(output).to include('["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "+ 16 more..."]')
    end
  end

  describe ".new_from" do
    it "creates a new step_context from an existing one" do
      new_context = described_class.new_from(step_context)
      expect(new_context.orig_value).to eq("abc")
      expect(new_context.current_value).to eq("abc")
      expect(new_context.type).to eq("some_type")
      expect(new_context.record).to eq({ "id_column" => "123" })
      expect(new_context.repetition).to eq(0)
      expect(new_context.cleanup_data).to eq(%w[a b c d e f g])
    end

    it "allows to pass any value as argument" do
      new_context = described_class.new_from(step_context, orig_value: "def", current_value: "def",
                                                           type: "another_type",
                                                           cleanup_data: %w[1 2 3 4 5 6 7 8 9 0],
                                                           record: { "id_column" => "456" },
                                                           repetition: 1)
      expect(new_context.orig_value).to eq("def")
      expect(new_context.current_value).to eq("def")
      expect(new_context.type).to eq("another_type")
      expect(new_context.record).to eq({ "id_column" => "456" })
      expect(new_context.repetition).to eq(1)
      expect(new_context.cleanup_data).to eq(%w[1 2 3 4 5 6 7 8 9 0])
    end
  end
end
