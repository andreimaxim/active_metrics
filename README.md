# ActiveMetrics

[![Gem Version](https://badge.fury.io/rb/active_metrics.svg)](https://badge.fury.io/rb/active_metrics)

A gem to simplify how metrics are being collected in Ruby-based applications.

As of now, the code is tested and optimized for usage on Heroku with the Librato
add-on and all the metrics are collected via the application log.

## Usage

Make sure that you start the collector somewhere in an initializer or before the
you want to start collecting metrics:

```ruby
ActiveMetrics::Collector.attach
```

Then include the module and then start collecting the metrics you want:

```ruby
require 'active_metrics'

class Foo

  include ActiveMetrics::Instrumentable

  def bar
    count 'method.bar'
  end

end
```

Available methods:

* `count`: add a value (default is 1) to a counter
* `measure`: individual measurements that comprise a statistical distribution (i.e. latency measurements)
* `sample`: simple key/numerical value pair

Be mindful of any kind of conflicts when including the module in your class.

### Disabling the metrics

For various environments (development and QA), the metrics can be a bit too
verbose and have very little value. In those cases, the metrics can be disabled
using by using the `SILENT_METRICS=1` environment variable.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/andreimaxim/active_metrics][active_metrics].

[active_metrics]: https://github.com/andreimaxim/active_metrics

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
