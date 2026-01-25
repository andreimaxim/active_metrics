# frozen_string_literal: true

require "active_support/notifications"
require "forwardable"

require "active_metrics/version"
require "active_metrics/configuration"
require "active_metrics/bucket"

require "active_metrics/sinks/stdout"
require "active_metrics/buckets/immediate"
require "active_metrics/buckets/interval"

require "active_metrics/collector"
require "active_metrics/instrumentable"

module ActiveMetrics
  extend Forwardable
  extend self

  def_delegators :config, :batching_mode, :interval, :silent?

  def setup
    yield(config) if block_given?
    reset_collector!
  end

  def collector
    @collector ||= build_collector
  end

  def config
    @config ||= Configuration.new
  end

  def reset_collector!
    @collector = nil
  end

  private

  def build_collector
    bucket = case batching_mode
    when :immediate
               Buckets::Immediate.new
    when :interval
               Buckets::Interval.new(interval: interval)
    end

    Collector.new(bucket: bucket, sink: Sinks::Stdout.new)
  end
end

# Flush remaining metrics on exit (guarded for reloadable environments)
unless defined?(@_active_metrics_at_exit_registered)
  @_active_metrics_at_exit_registered = true
  at_exit { ActiveMetrics.collector.flush(force: true) rescue nil }
end
