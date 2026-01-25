# frozen_string_literal: true

module ActiveMetrics
  module Sinks
    class Stdout
      def emit(entries)
        return if entries.nil? || entries.empty?

        tokens = entries.map { |metric, key, value| "#{metric}##{key}=#{value}" }
        $stdout.puts(tokens.join(" "))
      end
    end
  end
end
