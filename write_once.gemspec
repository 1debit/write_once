# frozen_string_literal: true

require_relative "lib/write_once/version"

Gem::Specification.new do |spec|
  spec.name = "write_once"
  spec.version = WriteOnce::VERSION
  spec.authors = ["Braden Staudacher"]
  spec.email = ["braden.staudacher@chime.com"]

  spec.summary = ""
  spec.description = ""
  spec.homepage = "https://github.com/1debit/write_once"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"


  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/1debit/write_once"
  spec.metadata["changelog_uri"] = "https://github.com/1debit/write_once/changelog.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", "~> 5.0"
  spec.add_development_dependency "activerecord", "= 7.1.2"
  spec.add_development_dependency "appraisal", "= 2.5.0"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "sqlite3"
end
