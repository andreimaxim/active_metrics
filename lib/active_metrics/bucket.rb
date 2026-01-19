# frozen_string_literal: true

module ActiveMetrics
  class Bucket
    def initialize
      @mutex = Mutex.new
      @entries = []
    end

    def add(metric, key, value)
      type = metric.to_sym
      v = value.to_f

      @mutex.synchronize do
        case type
        when :count
          increment(key, v)
        when :measure
          append(key, v)
        when :sample
          replace(key, v)
        end
      end
    end

    def empty?
      @mutex.synchronize { @entries.empty? }
    end

    def clear
      @mutex.synchronize { @entries.clear }
    end

    def drain
      entries = nil
      @mutex.synchronize do
        entries = @entries
        @entries = []
      end
      entries
    end

    private

    def increment(key, value)
      upsert("count", key, value) { |entry| entry[2] += value }
    end

    def append(key, value)
      @entries << [ "measure", key, value ]
    end

    def replace(key, value)
      upsert("sample", key, value) { |entry| entry[2] = value }
    end

    def upsert(type, key, value)
      entry = @entries.find { |e| e in [ ^type, ^key, _ ] }
      entry ? yield(entry) : @entries << [ type, key, value ]
    end
  end
end
