# frozen_string_literal: true

require "test_helper"

class ActiveMetricsTest < ActiveSupport::TestCase
  test "has a version number" do
    assert_not_nil ::ActiveMetrics::VERSION
  end

  test "setup works without a block" do
    assert_nothing_raised do
      ActiveMetrics.setup
    end
  end

  test "setup works with a block" do
    assert_nothing_raised do
      ActiveMetrics.setup do |config|
        config.interval = 10.0
      end
    end
  end

  test "collector returns a Collector instance" do
    ActiveMetrics.remove_instance_variable(:@collector) if ActiveMetrics.instance_variable_defined?(:@collector)

    collector = ActiveMetrics.collector

    assert_instance_of ActiveMetrics::Collector, collector
  end

  test "collector is memoized" do
    ActiveMetrics.remove_instance_variable(:@collector) if ActiveMetrics.instance_variable_defined?(:@collector)

    collector1 = ActiveMetrics.collector
    collector2 = ActiveMetrics.collector

    assert_same collector1, collector2
  end
end
