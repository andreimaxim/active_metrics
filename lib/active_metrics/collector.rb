module ActiveMetrics
  class Collector

    PREFIX = 'com.active_metrics'.freeze

    class << self

      # Should the metrics be silent?
      #
      # Useful especially in QA or development environments, where you'll
      # might not want your logs to be filled with various metrics.
      def silent?
        [1, '1', 'true'].include?(ENV['SILENT_METRICS'])
      end

      # Start subscribing to the metrics-related events.
      def attach
        ActiveSupport::Notifications.subscribe(/#{PREFIX}/i) do |name, _, _, _, data|
          deliver(name, data)
        end
      end

      # Deliver a metric to Librato
      #
      # According to the Heroku DevCenter there is already a tight integration
      # between Heroku logs and Librato so simply using `$stdout.puts` will be
      # enough, as long as a specific format is used.
      #
      # @param name [String] The name of the event being measured
      # @param data [Hash] a Hash with type of metric and the value to be recorded
      def deliver(name, data = {})
        key    = name.gsub(PREFIX, '')
        value  = data[:value]
        metric = data[:metric]

        $stdout.puts "#{metric}##{key}=#{value}" unless silent?
      end

      # Record an event
      #
      # @param event [String] The name of the event
      # @param payload [Hash] A hash that contains the event-related data.
      def record(event, payload = {})
        # Add a prefix to all events so things broadcasted using this method
        # will not get picked up by possibly other `ActiveSupport::Notifications`
        # subscribers.
        name = "#{PREFIX}#{event}"

        if block_given?
          ActiveSupport::Notifications.instrument(name, payload) { yield }
        else
          ActiveSupport::Notifications.instrument(name, payload)
        end
      end
    end
  end
end
