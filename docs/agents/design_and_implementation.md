# Design and Implementation

## Design principles

- Test observable behavior, not implementation — avoid testing internal state or private methods
- Keep configuration optional — defaults should work without calling `setup`
- Separate concerns — `setup` configures, `Collector.attach` starts; don't combine them
- DSL uses yield — `setup { |config| config.interval = 10.0 }` is explicit and IDE-friendly; avoid `instance_eval`
- Abstractions must pull their weight — prefer explicit code over metaprogramming unless the abstraction provides clear value
- Avoid deprecated APIs — don't use `ActiveSupport::Configurable` (deprecated in Rails 8.2); use the custom configuration class
- stdout is the only output — this gem targets Heroku/Librato; don't add configurable IO
- Don't design for testability — keep `reset` and similar methods private; tests should use mocking instead

## Implementation notes

- l2met format — all metric values are 64-bit floats; call `to_f` for counts, measures, and samples
- l2met sample semantics — `sample#` is a gauge (last value wins within the flush interval); if you need distribution stats, use `measure#` instead
- Prefix removal — use `sub(/\A#{PREFIX}/, "")` instead of `gsub` to avoid corrupting keys containing the prefix
- Use `Forwardable` — delegate config methods from the module to the configuration instance
- Predicate methods — configuration uses `silent?` with `attr_writer :silent` to follow Ruby conventions
- at_exit guards — use `defined?(@_var)` to prevent multiple hook registrations in reloadable environments
- Collector is a module-level instance — instantiated via `ActiveMetrics.collector`; `record` stays a stateless class method
- Mutex for bucket access — `@bucket_mutex.synchronize` protects both `add` and the swap during flush; concurrent-ruby structures don't help because `drain` requires cross-structure atomicity that lock-free containers can't provide
- Separation of concerns — bucket aggregates and returns tuples `[metric, key, value]`; collector formats and writes to stdout
- Avoid unnecessary indirection — don't wrap module methods in class methods just to call them (e.g., avoid `Collector.silent?` that just calls `ActiveMetrics.silent?`)
- Unify output paths — both immediate and interval modes use a single `emit` method; avoid separate write methods for each mode
- Keep branching logic together — `flush_if_due` is called in the `:interval` case block, not buried inside `buffer`, making the flow explicit

## API design patterns

- Return arrays over custom iterators — prefer `def metrics; [...]; end` over `def each_metric; yield(...); end`
- Pattern matching for array lookups — use `e in [^type, ^key, _]` with pinned variables for cleaner find predicates (requires Ruby 3.1+)
- Derive state instead of tracking it — prefer `def empty?; @hash.empty?; end` over maintaining counters
- Only add methods that are used — avoid exposing `size` or other accessors unless there's a concrete use case
- Unified storage — prefer one data structure over multiple parallel ones; Bucket uses a single `@entries` array with `upsert` for counts/samples and direct append for measures
- Linear scans are fine for small n — when cardinality is low (5-10 keys), avoid index overhead; simple `find` is clearer and fast enough
