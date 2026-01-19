# frozen_string_literal: true

module ActiveMetrics
  class Collector
    PREFIX = "com.active_metrics".freeze

    class << self
      def attach
        ActiveMetrics.collector.attach
      end

      def record(event, payload = {})
        name = "#{PREFIX}#{event}"

        if block_given?
          ActiveSupport::Notifications.instrument(name, payload) { yield }
        else
          ActiveSupport::Notifications.instrument(name, payload)
        end
      end
    end

    def initialize
      @bucket = Bucket.new
      @last_flush_at = monotonic_now
    end

    def attach
      ActiveSupport::Notifications.subscribe(/#{PREFIX}/i) do |name, _, _, _, data|
        deliver(name, data)
      end
    end

    def deliver(name, data = {})
      return if ActiveMetrics.silent?

      key = name.sub(/\A#{PREFIX}/, "")
      value = data[:value]
      metric = data[:metric]

      case ActiveMetrics.batching_mode
      when :immediate
        emit([ [ metric, key, value ] ])
      when :interval
        @bucket.add(metric, key, value)
        flush_if_due
      end
    end

    def flush
      @last_flush_at = monotonic_now
      emit(@bucket.drain)
    end

    private

    def flush_if_due
      return unless (monotonic_now - @last_flush_at) >= ActiveMetrics.interval

      flush
    end

    def emit(entries)
      return if entries.empty?

      tokens = entries.map { |metric, key, value| "#{metric}##{key}=#{value}" }
      $stdout.puts(tokens.join(" "))
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
