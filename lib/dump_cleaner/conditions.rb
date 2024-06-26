module DumpCleaner
  class Conditions
    def initialize(condition_config)
      @conditions = condition_config
    end

    def evaluate_to_true?(record:, column_value: nil)
      return false unless @conditions

      Array(@conditions).map do |condition_config|
        column = condition_config.column
        conversion, op, value = parse_condition(condition_config)
        (column ? record[column] : column_value).send(conversion || :itself).send(op, value)
      end.any?
    end

    def self.evaluate_to_true_in_step?(conditions:, step_context:)
      new(conditions).evaluate_to_true?(record: step_context.record, column_value: step_context.orig_value)
    end

    private

    def parse_condition(condition_config)
      condition_value = condition_config.value

      case condition_config.condition
      when "eq"
        [nil, "==", condition_value]
      when "ne"
        [nil, "!=", condition_value]
      when "start_with"
        [nil, :start_with?, condition_value]
      when "end_with"
        [nil, :end_with?, condition_value]
      when "non_zero"
        [:to_i, "!=", 0]
      else
        raise "Unknown condition #{condition_config.condition} for column #{condition_config.column}"
      end
    end
  end
end
