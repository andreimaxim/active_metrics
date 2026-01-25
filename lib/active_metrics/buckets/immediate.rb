# frozen_string_literal: true

module ActiveMetrics
  module Buckets
    class Immediate
      def ingest(metric, key, value)
        [ [ metric.to_s, key, value.to_f ] ]
      end

      def flush(force: false)
        nil
      end
    end
  end
end
