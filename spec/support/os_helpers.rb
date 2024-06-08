module Support
  module OsHelpers
    def with_modified_env(options)
      old_env = ENV.to_h.dup
      ENV.merge!(options)

      yield
    ensure
      ENV.merge!(old_env)
    end
  end
end
