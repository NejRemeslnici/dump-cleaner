# frozen_string_literal: true

module DumpCleaner
  class Config
    require "yaml"

    CleanupTableColumnConfig = Data.define(:name, :cleanup_type, :unique) do
      alias_method :unique?, :unique
    end

    CleanupStepConfig = Data.define(:step, :params)

    def initialize(config_file)
      @config = load(config_file)
      @steps_for = {}
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
      cleanup_config_for(type)["keep_same_conditions"]
    end

    def ignore_record_keep_same_conditions?(type)
      cleanup_config_for(type)["ignore_record_keep_same_conditions"]
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

    def cleanup_table_configs
      @cleanup_table_configs ||= Array(@config["cleanup_tables"]).map { CleanupTableConfig.new(_1) }
    end

    def cleanup_config_for(type)
      @config.dig("cleanup_types", type.to_s) ||
        raise("Missing type '#{type}' in the 'cleanup_types' section in config.")
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

      def keep_same_conditions
        @cleanup_table_config["keep_same_conditions"]
      end
    end
  end
end
