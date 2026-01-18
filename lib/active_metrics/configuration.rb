# frozen_string_literal: true

module ActiveMetrics
  class Configuration
    attr_accessor :batching_mode, :interval, :max_buffer_size, :overflow_policy,
                  :max_line_length
    attr_writer :silent

    def silent?
      @silent
    end

    def initialize
      @batching_mode = :immediate
      @interval = 5.0
      @max_buffer_size = 10_000
      @overflow_policy = :drop_newest
      @max_line_length = 1024

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
