# frozen_string_literal: true

require "test_helper"

class ActiveMetrics::BucketTest < ActiveSupport::TestCase
  def setup
    @bucket = ActiveMetrics::Bucket.new
  end

  test "new bucket is empty" do
    assert @bucket.empty?
    assert_equal 0, @bucket.event_count
  end

  test "adding a count increments event_count" do
    @bucket.add("count", "requests", 1)
    assert_equal 1, @bucket.event_count
    refute @bucket.empty?
  end

  test "counts are summed per key" do
    @bucket.add("count", "requests", 1)
    @bucket.add("count", "requests", 2)
    @bucket.add("count", "requests", 3)

    metrics = collect_metrics
    assert_equal [["count", "requests", 6.0]], metrics
  end

  test "counts coerce values to floats" do
    @bucket.add("count", "requests", "5")

    metrics = collect_metrics
    assert_equal [["count", "requests", 5.0]], metrics
  end

  test "measures collect all values per key" do
    @bucket.add("measure", "db.query", 10)
    @bucket.add("measure", "db.query", 20)
    @bucket.add("measure", "db.query", 30)

    metrics = collect_metrics
    assert_equal [
      ["measure", "db.query", 10.0],
      ["measure", "db.query", 20.0],
      ["measure", "db.query", 30.0]
    ], metrics
  end

  test "measures coerce values to floats" do
    @bucket.add("measure", "db.query", "15")

    metrics = collect_metrics
    assert_equal [["measure", "db.query", 15.0]], metrics
  end

  test "samples keep last value per key" do
    @bucket.add("sample", "queue.depth", 5)
    @bucket.add("sample", "queue.depth", 10)
    @bucket.add("sample", "queue.depth", 3)

    metrics = collect_metrics
    assert_equal [["sample", "queue.depth", 3.0]], metrics
  end

  test "samples coerce values to floats" do
    @bucket.add("sample", "queue.depth", "7")

    metrics = collect_metrics
    assert_equal [["sample", "queue.depth", 7.0]], metrics
  end

  test "metric type can be a symbol" do
    @bucket.add(:count, "requests", 1)
    @bucket.add(:measure, "timing", 50)
    @bucket.add(:sample, "gauge", 100)

    metrics = collect_metrics
    assert_includes metrics, ["count", "requests", 1.0]
    assert_includes metrics, ["measure", "timing", 50.0]
    assert_includes metrics, ["sample", "gauge", 100.0]
  end

  test "unknown metric types are ignored" do
    @bucket.add("unknown", "foo", 1)
    @bucket.add("invalid", "bar", 2)

    assert @bucket.empty?
    assert_equal 0, @bucket.event_count
  end

  test "clear resets the bucket" do
    @bucket.add("count", "requests", 5)
    @bucket.add("measure", "timing", 100)
    @bucket.add("sample", "gauge", 50)

    @bucket.clear

    assert @bucket.empty?
    assert_equal 0, @bucket.event_count
    assert_equal [], collect_metrics
  end

  test "each_metric yields count, measure, sample in order" do
    @bucket.add("count", "c1", 1)
    @bucket.add("measure", "m1", 10)
    @bucket.add("sample", "s1", 100)

    types = collect_metrics.map(&:first)
    assert_equal ["count", "measure", "sample"], types
  end

  test "multiple keys are tracked separately" do
    @bucket.add("count", "requests", 1)
    @bucket.add("count", "errors", 2)
    @bucket.add("measure", "db.read", 10)
    @bucket.add("measure", "db.write", 20)
    @bucket.add("sample", "memory", 100)
    @bucket.add("sample", "cpu", 50)

    metrics = collect_metrics
    assert_equal 6, metrics.size
    assert_equal 6, @bucket.event_count
  end

  private

  def collect_metrics
    result = []
    @bucket.each_metric { |metric, key, value| result << [metric, key, value] }
    result
  end
end
