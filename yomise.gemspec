# frozen_string_literal: true

require_relative "lib/yomise/version"

Gem::Specification.new do |spec|
  spec.name = "yomise"
  spec.version = Yomise::VERSION
  spec.authors = ["showata"]
  spec.email = ["shun_yamaguchi_tc@live.jp"]

  spec.summary       = "A simple way to Open .csv, .xls, .xlsx files. (formerly easy_sheet_io)"
  spec.description   = "A simple way to Open .csv, .xls, .xlsx files. You can convert it to 2D array, hash, data frame."
  spec.homepage      = "https://github.com/show-o-atakun/yomise"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/show-o-atakun/yomise"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "daru", ">= 0.3"
  spec.add_dependency "rover-df", ">= 0.2.7"
  spec.add_dependency "smarter_csv", ">= 1.4.2"
  spec.add_dependency "roo-xls", ">= 1.2.0"
  spec.add_dependency "spreadsheet", ">= 1.3.0"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
