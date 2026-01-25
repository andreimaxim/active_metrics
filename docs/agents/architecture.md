# Architecture

## Components

- `lib/active_metrics.rb` - Main entry point with `setup` DSL for configuration
- `lib/active_metrics/configuration.rb` - Configuration class with attr_accessor for all options
- `lib/active_metrics/collector.rb` - Subscribes to `ActiveSupport::Notifications` with `com.active_metrics` prefix and outputs metrics to stdout via `deliver`
- `lib/active_metrics/instrumentable.rb` - Mixin providing `count`, `measure`, and `sample` methods that publish to the collector
- `lib/active_metrics/bucket.rb` - Aggregates metrics into a single `@entries` array; counts are summed, measures appended individually, samples are last-wins (gauge semantics per l2met)

## Flow

Include `Instrumentable` → call `count`/`measure`/`sample` → `Collector.record` instruments via `ActiveSupport::Notifications` → `Collector.attach` subscriber receives and outputs to stdout.

## Batching Architecture

- Collector supports two modes: `:immediate` (output directly) and `:interval` (buffer into `Bucket` and flush)
- Bucket buffers directly — no intermediate queue; metrics go straight into the bucket for aggregation
- Swap-on-flush pattern — under mutex, swap `@bucket` for a fresh one, then write outside the lock to avoid blocking producers during IO
- `Bucket#drain` returns the metrics array and clears the bucket; collector handles formatting
- `emit` is the single output method; formats entries as l2met tokens and writes to stdout
- Opportunistic flush: `flush_if_due` checks `flush_due?(interval)` after each buffered metric
- `at_exit` hook flushes remaining metrics on shutdown
