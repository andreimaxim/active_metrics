# frozen_string_literal: true

module ActiveMetrics
  class Bucket
    def initialize
      @counts = Hash.new(0.0)
      @measures = Hash.new { |h, k| h[k] = [] }
      @samples = {}
    end

    def add(metric, key, value)
      metric = metric.to_s
      v = value.to_f

      case metric
      when "count"
        @counts[key] += v
      when "measure"
        @measures[key] << v
      when "sample"
        @samples[key] = v
      end
    end

    def size
      @counts.size + @measures.values.sum(&:size) + @samples.size
    end

    def empty?
      size == 0
    end

    def clear
      @counts.clear
      @measures.clear
      @samples.clear
    end

    def metrics
      @counts.map { |k, v| [ "count", k, v ] } +
        @measures.flat_map { |k, vs| vs.map { |v| [ "measure", k, v ] } } +
        @samples.map { |k, v| [ "sample", k, v ] }
    end
  end
end
