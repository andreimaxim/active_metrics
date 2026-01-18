# frozen_string_literal: true

module ActiveMetrics
  class Configuration
    DEFAULTS = {
      batching_mode: :immediate,
      interval: 5.0,
      max_buffer_size: 10_000,
      overflow_policy: :drop_newest,
      max_line_length: 1024
    }.freeze

    def initialize
      DEFAULTS.each do |key, value|
        instance_variable_set(:"@#{key}", value)
      end

      @silent = silent_metrics? || test_environment?
    end

    DEFAULTS.each_key do |key|
      define_method(key) do |value = nil|
        if value.nil?
          instance_variable_get(:"@#{key}")
        else
          instance_variable_set(:"@#{key}", value)
        end
      end

      define_method(:"#{key}=") do |value|
        instance_variable_set(:"@#{key}", value)
      end
    end

    def silent(value = nil)
      if value.nil?
        @silent
      else
        @silent = value
      end
    end

    def silent=(value)
      @silent = value
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
