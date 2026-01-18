# frozen_string_literal: true

require "active_support/notifications"
require "forwardable"

require "active_metrics/version"
require "active_metrics/configuration"
require "active_metrics/bucket"

require "active_metrics/collector"
require "active_metrics/instrumentable"

module ActiveMetrics
  extend Forwardable
  extend self

  def setup
    yield(config) if block_given?
  end

  def_delegators :config, :batching_mode, :interval, :max_buffer_size, :silent?

  private

  def config
    @config ||= Configuration.new
  end
end

# Flush remaining metrics on exit (guarded for reloadable environments)
unless defined?(@_active_metrics_at_exit_registered)
  @_active_metrics_at_exit_registered = true
  at_exit { ActiveMetrics::Collector.flush rescue nil }
end
