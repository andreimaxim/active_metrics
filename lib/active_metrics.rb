# frozen_string_literal: true

require "active_support/notifications"

require "active_metrics/version"
require "active_metrics/configuration"
require "active_metrics/collector"
require "active_metrics/instrumentable"

module ActiveMetrics
  extend self

  def setup
    yield(config) if block_given?
  end

  private

    def config
      @config ||= Configuration.new
    end
end
