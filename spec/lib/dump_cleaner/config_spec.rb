# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe DumpCleaner::Config do
  def with_config_file(content)
    Tempfile.create("config") do |file|
      file.write(content)
      file.close

      yield file.path
    end
  end

  before do
    DumpCleaner::Log.instance.reset
  end

  describe "#initialize" do
    it "sets logger level right after loading config" do
      expect(DumpCleaner::Log.instance.level).to eq(Logger::INFO)

      with_config_file("dump_cleaner:\n  log_level: debug") do |config_file|
        described_class.new(config_file)
        expect(DumpCleaner::Log.instance.level).to eq(Logger::DEBUG)
      end
    end
  end

  describe "#dump_format" do
    it "returns the dump format" do
      with_config_file("dump:\n  format: some_format") do |config_file|
        expect(described_class.new(config_file).dump_format).to eq("some_format")
      end
    end
  end

  describe "#steps_for" do
    it "returns the steps for the given type and phase" do
      config = <<~YAML
        cleanup_types:
          some_type:
            phase:
              - step: Step1
                params:
                  param1: some_file.yml
                  param2: key
              - step: Step2
                params:
                  foo: bar
      YAML

      with_config_file(config) do |config_file|
        expect(described_class.new(config_file).steps_for("some_type", :phase))
          .to eq([
                   DumpCleaner::Config::CleanupStepConfig.new(step: "Step1",
                                                              params: { param1: "some_file.yml", param2: "key" }),
                   DumpCleaner::Config::CleanupStepConfig.new(step: "Step2",
                                                              params: { foo: "bar" })
                 ])
      end
    end

    it "returns an array of steps even when a single step is defined" do
      config = <<~YAML
        cleanup_types:
          some_type:
            phase:
              - step: Step1
      YAML

      with_config_file(config) do |config_file|
        expect(described_class.new(config_file).steps_for("some_type", :phase))
          .to eq([DumpCleaner::Config::CleanupStepConfig.new(step: "Step1", params: {})])
      end
    end

    it "raises an error if the type configuration is missing or empty" do
      config = <<~YAML
        cleanup_types:
          some_type:
            phase:
              - step: Step1
          another_type:
      YAML

      with_config_file(config) do |config_file|
        configuration = described_class.new(config_file)
        expect { configuration.steps_for("some_type", :phase) }.not_to raise_error
        expect { configuration.steps_for("empty_type", :phase) }
          .to raise_error(DumpCleaner::Config::ConfigurationError, /Missing or empty type 'empty_type'/)
        expect { configuration.steps_for("non_existant", :phase) }
          .to raise_error(DumpCleaner::Config::ConfigurationError, /Missing or empty type 'non_existant'/)
      end
    end
  end

  describe "#keep_same_conditions" do
    it "returns the keep_same_conditions for the given type" do
      config = <<~YAML
        cleanup_types:
          some_type:
            keep_same_conditions:
              - condition: operator
                value: value
      YAML

      with_config_file(config) do |config_file|
        expect(described_class.new(config_file).keep_same_conditions("some_type"))
          .to eq([DumpCleaner::Config::ConditionConfig.new(condition: "operator", value: "value", column: nil)])
      end
    end
  end

  describe "#ignore_keep_same_record_conditions?" do
    it "returns true if the ignore_keep_same_record_conditions is set to true" do
      config = <<~YAML
        cleanup_types:
          some_type:
            ignore_keep_same_record_conditions: true
          another_type:
            phase:
              - step: Step1
      YAML

      with_config_file(config) do |config_file|
        configuration = described_class.new(config_file)
        expect(configuration.ignore_keep_same_record_conditions?("some_type")).to eq(true)
        expect(configuration.ignore_keep_same_record_conditions?("another_type")).to eq(false)
      end
    end
  end

  describe "#cleanup_tables" do
    it "returns an array of db and table names" do
      config = <<~YAML
        cleanup_tables:
          - db: some_db
            table: some_table
          - db: foo
            table: bar
      YAML

      with_config_file(config) do |config_file|
        expect(described_class.new(config_file).cleanup_tables).to eq([%w[some_db some_table], %w[foo bar]])
      end
    end
  end

  describe "#cleanup_table_config" do
    it "returns the configuration for the given table" do
      config = <<~YAML
        cleanup_tables:
          - db: some_db
            table: some_table
            id_column: some_non_default_id_column
            columns:
              - name: column1
                cleanup_type: some_type
              - name: column2
                cleanup_type: another_type
                unique: true
            record_context_columns:
              - column1
              - column2
            keep_same_record_conditions:
              - condition: operator
                value: value
                column: column1
      YAML

      with_config_file(config) do |config_file|
        table_config = described_class.new(config_file).cleanup_table_config(db: "some_db", table: "some_table")
        expect(table_config).to be_a(DumpCleaner::Config::CleanupTableConfig)
        expect(table_config.db).to eq("some_db")
        expect(table_config.table).to eq("some_table")
        expect(table_config.id_column).to eq("some_non_default_id_column")
        expect(table_config.columns)
          .to eq([
                   DumpCleaner::Config::CleanupTableColumnConfig.new(name: "column1", cleanup_type: "some_type",
                                                                     unique: false),
                   DumpCleaner::Config::CleanupTableColumnConfig.new(name: "column2", cleanup_type: "another_type",
                                                                     unique: true)
                 ])
        expect(table_config.columns.map(&:unique_column?)).to eq([false, true])
        expect(table_config.record_context_columns).to eq(%w[column1 column2])
        expect(table_config.keep_same_record_conditions)
          .to eq([DumpCleaner::Config::ConditionConfig.new(condition: "operator", value: "value", column: "column1")])
      end
    end

    it "returns 'id' in the id_column by default" do
      config = <<~YAML
        cleanup_tables:
          - db: some_db
            table: some_table
      YAML

      with_config_file(config) do |config_file|
        table_config = described_class.new(config_file).cleanup_table_config(db: "some_db", table: "some_table")
        expect(table_config.id_column).to eq("id")
      end
    end

    it "returns ['id'] in the record_context_columns by default" do
      config = <<~YAML
        cleanup_tables:
          - db: some_db
            table: some_table
      YAML

      with_config_file(config) do |config_file|
        table_config = described_class.new(config_file).cleanup_table_config(db: "some_db", table: "some_table")
        expect(table_config.record_context_columns).to eq(["id"])
      end
    end
  end
end
