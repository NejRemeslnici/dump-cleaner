module DumpCleaner
  class Conditions
    def initialize(condition_config)
      @conditions = condition_config
    end

    def evaluate_to_true?(record, column_value: nil)
      return false unless @conditions

      Array(@conditions).map do |keep_config|
        column = keep_config["column"]
        condition_value = keep_config["value"]
        conversion, op, value = case keep_config["condition"]
                                when "eq"
                                  [nil, "==", condition_value]
                                when "ne"
                                  [nil, "!=", condition_value]
                                when "non_zero"
                                  [:to_i, "!=", 0]
                                when "start_with"
                                  [nil, :start_with?, condition_value]
                                when "end_with"
                                  [nil, :end_with?, condition_value]
                                else
                                  raise "Unknown condition #{keep_config['condition']} for column #{column}"
                                end
        (column ? record[column] : column_value).send(conversion || :itself).send(op, value)
      end.any?
    end
  end
end
