# Testing Patterns

- Use Mocha for mocking — `stubs(:method).returns(value)` syntax via the `mocha` gem
- Stub `$stdout.puts` — `$stdout.stubs(:puts).with { |line| @output << line }` to capture output
- Stub config and reset collector — `ActiveMetrics.stubs(:config).returns(@config)` and `ActiveMetrics::Collector.instance.reset` for test isolation
- Unsubscribe in teardown — `attach` returns a subscriber; capture it and call `ActiveSupport::Notifications.unsubscribe(@subscriber)` to prevent subscription accumulation
- `ActiveSupport::Notifications.unsubscribe` does not accept regex for removal — you must pass the subscriber handle returned by `subscribe`
