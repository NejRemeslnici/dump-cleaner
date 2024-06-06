# frozen_string_literal: true

module DumpCleaner
  module Cleanup
    module DataSourceSteps
      class Base
        require "forwardable"
        require "zlib"

        extend Forwardable

        def_delegators :step_context, :cleanup_data, :type

        attr_reader :step_context

        def initialize(step_context)
          @step_context = step_context
        end

        def raise_params_error(error)
          step = self.class.name.split("::").last
          raise ArgumentError, "Invalid data source step params: type=#{type}, step=#{step}: #{error}"
        end
      end
    end
  end
end
