module ActiveMetrics
  ##
  # Custom metrics for Librato
  module Instrumentable

    # Count log lines are used to submit increments to Librato.
    #
    # You can submit increments as frequently as desired and every minute the
    # current total will be flushed to Librato and reset to zero.
    #
    # @param event [String] The name of the event
    # @param number [Integer] The number to increment the current count (defaults to 1)
    def count(event, number = 1)
      ActiveMetrics::Collector.record(event, { metric: 'count', value: number })
    end

    # Measure log lines are used to submit individual measurements that comprise
    # a statistical distribution. The most common use case are timings i.e.
    # latency measurements, but it can also be used to represent non-temporal
    # distributions such as counts.
    #
    # You can submit as many measures as you’d like (typically they are
    # submitted per-request) and every minute Librato will calculate/record a
    # complete set of summary statistics over the measures submitted in that
    # interval.
    #
    # @param event [String] The name of the event
    # @param value [Integer, String] The value measured.
    def measure(event, value = 0)
      ActiveMetrics::Collector.record(event, { metric: 'measure', value: value })
    end

    # Sample metrics are used to convey simple key/numerical value pairs when
    # you are already calculating some kind of summary statistic in your app and
    # merely need a simple transport mechanism to Librato.
    #
    # Typically you would submit sample metrics on some periodic tick and set
    # said period on the metric in Librato.
    #
    # @param key [String] The name of the sample
    # @param value [Object] The value of the sample
    def sample(key, value)
      ActiveMetrics::Collector.record(key, { metric: 'sample', value: value })
    end
  end
end