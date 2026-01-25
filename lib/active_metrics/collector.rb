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

    def initialize(bucket:, sink:)
      @bucket = bucket
      @sink = sink
    end

    def attach
      ActiveSupport::Notifications.subscribe(/#{PREFIX}/i) do |name, _, _, _, data|
        deliver(name, data)
      end
    end

    def deliver(name, data = {})
      return if ActiveMetrics.silent?

      key = name.sub(/\A#{PREFIX}/, "")
      metric = data[:metric]
      value = data[:value]

      batch = @bucket.ingest(metric, key, value)
      @sink.emit(batch)
    end

    def flush(force: false)
      batch = @bucket.flush(force: force)
      @sink.emit(batch)
    end
  end
end
