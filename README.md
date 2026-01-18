# ActiveMetrics

[![Gem Version](https://badge.fury.io/rb/active_metrics.svg)](https://badge.fury.io/rb/active_metrics)

A gem to simplify how metrics are being collected in Ruby-based applications.

As of now, the code is tested and optimized for usage on Heroku with the Librato
add-on and all the metrics are collected via the application log.

## Usage

### Setup

Start the collector in an initializer:

```ruby
# config/initializers/active_metrics.rb
ActiveMetrics::Collector.attach
```

If you need to customize the configuration:

```ruby
ActiveMetrics.setup do
  batching_mode :interval       # :immediate (default), :interval, or :request
  interval 10.0                 # seconds between flushes (default: 5.0)
  max_buffer_size 5_000         # max events before overflow (default: 10_000)
  overflow_policy :drop_oldest  # :drop_newest (default), :drop_oldest, or :flush
  max_line_length 2048          # max chars per output line (default: 1024)
end

ActiveMetrics::Collector.attach
```

### Collecting Metrics

Include the module in your class and start collecting metrics:

```ruby
class Foo
  include ActiveMetrics::Instrumentable

  def bar
    count "method.bar"
  end
end
```

Available methods:

* `count`: add a value (default is 1) to a counter
* `measure`: individual measurements that comprise a statistical distribution (i.e. latency measurements)
* `sample`: simple key/numerical value pair

Be mindful of any kind of conflicts when including the module in your class.

### Disabling Metrics

For various environments (development and QA), the metrics can be a bit too
verbose and have very little value. In those cases, the metrics can be disabled
by using the `SILENT_METRICS=1` environment variable.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/andreimaxim/active_metrics][active_metrics].

[active_metrics]: https://github.com/andreimaxim/active_metrics

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
