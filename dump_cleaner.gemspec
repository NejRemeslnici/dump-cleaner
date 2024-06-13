# frozen_string_literal: true

require_relative "lib/dump_cleaner/version"

Gem::Specification.new do |spec|
  spec.name = "dump_cleaner"
  spec.version = DumpCleaner::VERSION
  spec.authors = ["Matouš Borák"]
  spec.email = ["matous.borak@nejremeslnici.cz"]

  spec.summary = "Anonymizes data in logical database dumps."
  spec.description = "Deterministically anonymizes data in logical database dumps. Useful for importing (anonymized) production data into development environments."
  spec.homepage = "https://github.com/NejRemeslnici/dump-cleaner"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/NejRemeslnici/dump-cleaner"
  spec.metadata["changelog_uri"] = "https://github.com/NejRemeslnici/dump-cleaner/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "zeitwerk", "~> 2.6"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
