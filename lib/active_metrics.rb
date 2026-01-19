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

  def_delegators :config, :batching_mode, :interval, :silent?

  def setup
    yield(config) if block_given?
  end

  def collector
    @collector ||= Collector.new
  end

  def config
    @config ||= Configuration.new
  end
end

# Flush remaining metrics on exit (guarded for reloadable environments)
unless defined?(@_active_metrics_at_exit_registered)
  @_active_metrics_at_exit_registered = true
  at_exit { ActiveMetrics.collector.flush rescue nil }
end
