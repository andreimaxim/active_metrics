# ActiveMetrics

[![Build Status](https://travis-ci.org/andreimaxim/active_metrics.svg?branch=master)](https://travis-ci.org/andreimaxim/active_metrics)
[![Maintainability](https://api.codeclimate.com/v1/badges/50e30f3b65985e299e9e/maintainability)](https://codeclimate.com/github/andreimaxim/active_metrics/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/50e30f3b65985e299e9e/test_coverage)](https://codeclimate.com/github/andreimaxim/active_metrics/test_coverage)


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

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/andreimaxim/active_metrics.]()

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
