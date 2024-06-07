# frozen_string_literal: true

module DumpCleaner
  class Config
    require "yaml"

    CleanupTableColumnConfig = Data.define(:name, :cleanup_type, :unique) do
      alias_method :unique_column?, :unique
    end

    CleanupStepConfig = Data.define(:step, :params)

    ConditionConfig = Data.define(:column, :condition, :value)

    class ConfigurationError < StandardError; end

    def initialize(config_file)
      @config = load(config_file) || {}
      @steps_for = {}
      @keep_same_conditions = {}

      set_log_level
    end

    def dump_format
      @config.dig("dump", "format")
    end

    def steps_for(type, phase)
      @steps_for[type] ||= {}
      @steps_for[type][phase.to_s] ||= Array(cleanup_config_for(type)[phase.to_s]).map do
        CleanupStepConfig.new(step: _1["step"], params: (_1["params"] || {}).transform_keys(&:to_sym))
      end
    end

    def keep_same_conditions(type)
      @keep_same_conditions[type] ||= cleanup_config_for(type)["keep_same_conditions"].map do
        ConditionConfig.new(condition: _1["condition"], value: _1["value"], column: nil)
      end
    end

    def ignore_keep_same_record_conditions?(type)
      cleanup_config_for(type)["ignore_keep_same_record_conditions"] == true
    end

    def cleanup_tables
      cleanup_table_configs.map { [_1.db, _1.table] }
    end

    def cleanup_table_config(db:, table:)
      cleanup_table_configs.find { _1.db == db && _1.table == table }
    end

    private

    def load(config_file)
      YAML.load_file(config_file)
    end

    def set_log_level
      if (level = @config.dig("dump_cleaner", "log_level"))
        Log.instance.level = level
      end
    end

    def cleanup_table_configs
      @cleanup_table_configs ||= Array(@config["cleanup_tables"]).map { CleanupTableConfig.new(_1) }
    end

    def cleanup_config_for(type)
      @config.dig("cleanup_types", type.to_s) ||
        raise(ConfigurationError, "Missing or empty type '#{type}' in the 'cleanup_types' section in config.")
    end

    class CleanupTableConfig
      def initialize(cleanup_table_config)
        @cleanup_table_config = cleanup_table_config
      end

      def db
        @cleanup_table_config["db"]
      end

      def table
        @cleanup_table_config["table"]
      end

      def id_column
        @cleanup_table_config["id_column"] || "id"
      end

      def columns
        @columns ||= Array(@cleanup_table_config["columns"]).map do
          CleanupTableColumnConfig.new(name: _1["name"], cleanup_type: _1["cleanup_type"], unique: _1["unique"] == true)
        end
      end

      def record_context_columns
        @cleanup_table_config["record_context_columns"] || ["id"]
      end

      def keep_same_record_conditions
        @keep_same_record_conditions ||= @cleanup_table_config["keep_same_record_conditions"].map do
          ConditionConfig.new(condition: _1["condition"], value: _1["value"], column: _1["column"])
        end
      end
    end
  end
end
