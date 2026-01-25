# frozen_string_literal: true

module ActiveMetrics
  module Buckets
    class Interval
      def initialize(interval:, bucket: Bucket.new)
        @interval = interval
        @bucket = bucket
      end

      def ingest(metric, key, value)
        @bucket.add(metric, key, value)
        @bucket.drain(interval: @interval)
      end

      def flush(force: false)
        interval = force ? nil : @interval
        @bucket.drain(interval: interval)
      end
    end
  end
end
