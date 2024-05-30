# frozen_string_literal: true

module DumpCleaner
  class Config
    require "yaml"

    ColumnConfig = Data.define(:name, :cleanup_type)

    def initialize(config_file)
      @config = load(config_file)
    end

    def dump_format
      @config.dig("dump", "format")
    end

    def steps_for(type, phase)
      cleanup_config_for(type)[phase.to_s] || []
    end

    def keep_same_conditions(type)
      cleanup_config_for(type)["keep_same_conditions"]
    end

    def ignore_record_keep_same_conditions?(type)
      cleanup_config_for(type)["ignore_record_keep_same_conditions"]
    end

    def uniqueness_wanted?(type)
      cleanup_config_for(type)["unique"]
    end

    def table_cleanups
      @table_cleanups ||= Array(@config["table_cleanups"]).map { TableCleanupConfig.new(_1) }
    end

    class TableCleanupConfig
      def initialize(table_cleanup_config)
        @table_cleanup_config = table_cleanup_config
      end

      def db
        @table_cleanup_config["db"]
      end

      def table
        @table_cleanup_config["table"]
      end

      def columns
        @columns ||= Array(@table_cleanup_config["columns"]).map do
          ColumnConfig.new(name: _1["name"], cleanup_type: _1["cleanup_data_type"])
        end
      end

      def record_context_columns
        @table_cleanup_config["record_context_columns"] || ["id"]
      end

      def keep_same_conditions
        @table_cleanup_config["keep_same_conditions"]
      end
    end

    private

    def load(config_file)
      YAML.load_file(config_file)
    end

    def cleanup_config_for(type)
      @config.dig("cleanup_types", type.to_s) ||
        raise("Missing type '#{type}' in the 'cleanup_types' section in config.")
    end
  end
end
