# frozen_string_literal: true

module ActiveMetrics
  class Collector
    PREFIX = "com.active_metrics".freeze

    class << self
      def silent?
        ActiveMetrics.silent?
      end

      def attach
        ActiveSupport::Notifications.subscribe(/#{PREFIX}/i) do |name, _, _, _, data|
          deliver(name, data)
        end
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
        return if silent?

        key = name.sub(/\A#{PREFIX}/, "")
        value = data[:value]
        metric = data[:metric]

        case ActiveMetrics.batching_mode
        when :immediate
          write_immediate(metric, key, value)
        when :interval
          flush_if_due
          bucket.add(metric, key, value)
          check_overflow
        end
      end

      def flush
        return if bucket.empty?

        tokens = bucket.metrics.map { |metric, key, value| "#{metric}##{key}=#{value}" }
        $stdout.puts(tokens.join(" ")) unless tokens.empty?

        bucket.clear
        @last_flush_at = monotonic_now
      end

      private

      def reset
        @bucket = nil
        @last_flush_at = nil
      end

      def bucket
        @bucket ||= Bucket.new
      end

      def last_flush_at
        @last_flush_at ||= monotonic_now
      end

      def flush_if_due
        interval = ActiveMetrics.interval
        return if interval.to_f <= 0
        return if (monotonic_now - last_flush_at) < interval

        flush
      end

      def check_overflow
        max = ActiveMetrics.max_buffer_size
        return if max <= 0 || bucket.size < max

        flush
      end

      def monotonic_now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def write_immediate(metric, key, value)
        $stdout.puts("#{metric}##{key}=#{value}")
      end
    end
  end
end
