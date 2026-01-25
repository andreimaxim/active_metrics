# ActiveMetrics

Ruby gem collecting metrics via `ActiveSupport::Notifications` and emitting Librato l2met lines to stdout.

## Essentials

- Package manager: Bundler (`bundle install`)
- Tests: `bundle exec rake test`; coverage: `bundle exec rake coverage` (writes to `coverage/`)
- Lint: `bin/rubocop -A`
- ActiveSupport 7.2 matrix: `bundle exec appraisal activesupport-7.2 rake test`

## More detail

- Architecture and batching: [docs/agents/architecture.md](docs/agents/architecture.md)
- Code style and conventions: [docs/agents/conventions.md](docs/agents/conventions.md)
- Design and implementation notes: [docs/agents/design_and_implementation.md](docs/agents/design_and_implementation.md)
- Testing patterns: [docs/agents/testing.md](docs/agents/testing.md)
