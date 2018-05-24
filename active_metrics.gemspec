
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_metrics/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_metrics'
  spec.version       = ActiveMetrics::VERSION
  spec.authors       = ['Andrei Maxim']
  spec.email         = ['andrei@andreimaxim.ro']

  spec.summary       = %q{Metrics based on ActiveSupport::Notifications}
  spec.homepage      = 'https://github.com/andreimaxim/active_metrics'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'simplecov', '~> 0.15'
  spec.add_development_dependency 'pry', '~> 0.11'

  # This is a bit sketchy for now as we generally need just
  # ActiveSupport::Notifications but specifying a fixed version might create
  # issues with various Rails installations (AS::N v4 vs Rails v5 for example)
  #
  # This will have to do for now, unless somebody has a better idea.
  spec .add_dependency 'activesupport', '>= 3.0.0'
end
