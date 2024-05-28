module DumpCleaner
  class Conditions
    def initialize(condition_config)
      @conditions = condition_config
    end

    def evaluates_to_true?(record)
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
                                when "end_with"
                                  [nil, :end_with?, condition_value]
                                else
                                  raise "Unknown condition #{keep_config['condition']} for column #{column}"
                                end
        record[column].send(conversion || :itself).send(op, value)
      end.any?
    end
  end
end
