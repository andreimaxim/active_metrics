# frozen_string_literal: true

module ActiveMetrics
  class Formatter
    def initialize(source: nil, max_line_length: 1024)
      @source = source
      @max_line_length = max_line_length
    end

    def format_lines(bucket)
      tokens = []
      bucket.each_metric do |metric, key, value|
        tokens << "#{metric}##{key}=#{value}"
      end

      prefix = @source ? "source=#{@source} " : ""
      split_into_lines(tokens, prefix)
    end

    private

    def split_into_lines(tokens, prefix)
      return [] if tokens.empty?

      lines = []
      current = prefix.dup

      tokens.each do |token|
        candidate = current.empty? || current == prefix ? "#{current}#{token}" : "#{current} #{token}"

        if candidate.bytesize > @max_line_length && current != prefix
          lines << current
          current = "#{prefix}#{token}"
        else
          current = candidate
        end
      end

      lines << current unless current == prefix || current.empty?
      lines
    end
  end
end
