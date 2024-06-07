# frozen_string_literal: true

require "spec_helper"

RSpec.describe DumpCleaner::Log do
  let(:log) { described_class.instance }

  before do
    log.init_log_level
  end

  describe "#init_log_level" do
    it "(re-)initializes the log level to INFO" do
      log.level = "debug"
      expect(log.level).to eq(Logger::DEBUG)

      log.init_log_level
      expect(log.level).to eq(Logger::INFO)
    end
  end

  describe ".info" do
    it "formats the message in the custom format" do
      block = lambda do
        log.reopen($stdout)
        log.info { "Some message" }
      end
      expect(&block).to output(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \+\d{4} INFO: Some message/).to_stdout
    end
  end
end
