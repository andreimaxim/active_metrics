# frozen_string_literal: true

module ActiveMetrics
  class Configuration
    attr_accessor :batching_mode, :interval, :silent

    alias_method :silent?, :silent

    def initialize
      @batching_mode = :immediate
      @interval = 5.0
      @silent = silent_metrics? || test_environment?
    end

    private

    def test_environment?
      ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test"
    end

    def silent_metrics?
      %w[1 true].include?(ENV["SILENT_METRICS"])
    end
  end
end
