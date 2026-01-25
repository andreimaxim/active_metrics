# Code Style and Conventions

- Use double quotes for strings (rubocop-rails-omakase style)
- Freeze string constants
- Document public methods with YARD-style `@param` and `@return` tags
- Tests use `ActiveSupport::TestCase` with `test "description"` DSL
- Environment variable `SILENT_METRICS=1` disables metric output
- Prefer `assert_not_*` over `refute_*` (ActiveSupport style)
- Use expressive method names — prefer `emit` over `write` for metrics output (idiomatic in observability libraries)
