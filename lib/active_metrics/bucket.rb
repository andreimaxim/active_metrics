# frozen_string_literal: true

module ActiveMetrics
  class Bucket
    attr_reader :event_count

    def initialize
      @counts = Hash.new(0.0)
      @measures = Hash.new { |h, k| h[k] = [] }
      @samples = {}
      @event_count = 0
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
      else
        return
      end

      @event_count += 1
    end

    def empty?
      @event_count == 0
    end

    def clear
      @counts.clear
      @measures.clear
      @samples.clear
      @event_count = 0
    end

    def each_metric
      @counts.each { |k, v| yield("count", k, v) }
      @measures.each { |k, vs| vs.each { |v| yield("measure", k, v) } }
      @samples.each { |k, v| yield("sample", k, v) }
    end
  end
end
