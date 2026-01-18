# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_metrics/version"

Gem::Specification.new do |spec|
  spec.name          = "active_metrics"
  spec.version       = ActiveMetrics::VERSION
  spec.authors       = [ "Andrei Maxim" ]
  spec.email         = [ "andrei@andreimaxim.ro" ]

  spec.summary       = "Metrics based on ActiveSupport::Notifications"
  spec.homepage      = "https://github.com/andreimaxim/active_metrics"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = [ "lib" ]

  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "mocha", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop-minitest"
  spec.add_development_dependency "rubocop-rails-omakase"
  spec.add_development_dependency "simplecov", "~> 0.15"

  spec.add_dependency "activesupport", ">= 7.2"
end
