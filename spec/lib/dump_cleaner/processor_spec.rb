# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe DumpCleaner::Processor do
  def with_config_file(content)
    Tempfile.create("config") do |file|
      file.write(content)
      file.close

      yield file.path
    end
  end

  describe "#run" do
    it "calls the proper cleaner and it's hooks" do
      with_config_file("dump:\n  format: mysql_shell") do |config_file|
        double = instance_double("DumpCleaner::Cleaners::MysqlShellDumpCleaner")
        allow(DumpCleaner::Cleaners::MysqlShellDumpCleaner).to receive(:new).and_return(double)

        expect(double).to receive(:pre_cleanup)
        expect(double).to receive(:clean)
        expect(double).to receive(:post_cleanup)

        options = DumpCleaner::Options.new(["-f", "source", "-t", "dest", "-c", config_file])
        described_class.new(options).run
      end
    end

    it "raises error it unknown dump format encountered" do
      with_config_file("dump:\n  format: non_existent") do |config_file|
        options = DumpCleaner::Options.new(["-f", "source", "-t", "dest", "-c", config_file])

        expect do
          described_class.new(options).run
        end.to raise_error(DumpCleaner::Config::ConfigurationError, /Unsupported dump format/)
      end
    end
  end
end
