# frozen_string_literal: true

require "singleton"
require "concurrent"

module ActiveMetrics
  class Collector
    include Singleton

    PREFIX = "com.active_metrics".freeze

    class << self
      def attach
        instance.attach
      end

      def record(event, payload = {})
        name = "#{PREFIX}#{event}"

        if block_given?
          ActiveSupport::Notifications.instrument(name, payload) { yield }
        else
          ActiveSupport::Notifications.instrument(name, payload)
        end
      end

      def deliver(name, data = {})
        instance.deliver(name, data)
      end

      def flush
        instance.flush
      end
    end

    def initialize
      @queue = Queue.new
      @bucket = Bucket.new
      @last_flush_at = monotonic_now
      @flush_mutex = Mutex.new
      @shutdown = false
    end

    def attach
      ActiveSupport::Notifications.subscribe(/#{PREFIX}/i) do |name, _, _, _, data|
        deliver(name, data)
      end
    end

    def deliver(name, data = {})
      return if ActiveMetrics.silent?
      return if @shutdown

      key = name.sub(/\A#{PREFIX}/, "")
      value = data[:value]
      metric = data[:metric]

      case ActiveMetrics.batching_mode
      when :immediate
        write_immediate(metric, key, value)
      when :interval
        enqueue(metric, key, value)
      end
    end

    def flush
      return if @shutdown && @queue.empty?

      @flush_mutex.synchronize do
        bucket = Bucket.new

        until @queue.empty?
          metric, key, value = @queue.pop(true)
          bucket.add(metric, key, value)
        end

        write_bucket(bucket) unless bucket.empty?
        @last_flush_at = monotonic_now
      rescue ThreadError
      end
    end

    def stop
      return if @shutdown
      @shutdown = true
      flush
    end

    def reset
      @queue.clear
      @shutdown = false
      @last_flush_at = monotonic_now
    end

    private

    def enqueue(metric, key, value)
      @queue << [ metric, key, value ]

      flush_if_due
      check_overflow
    end

    def flush_if_due
      interval = ActiveMetrics.interval

      return if interval.to_f <= 0
      return if (monotonic_now - @last_flush_at) < interval

      flush
    end

    def check_overflow
      max = ActiveMetrics.max_buffer_size
      return if max <= 0 || @queue.size < max

      flush
    end

    def write_immediate(metric, key, value)
      $stdout.puts("#{metric}##{key}=#{value}")
    end

    def write_bucket(bucket)
      tokens = bucket.metrics.map { |metric, key, value| "#{metric}##{key}=#{value}" }
      $stdout.puts(tokens.join(" ")) unless tokens.empty?
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
