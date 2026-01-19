# frozen_string_literal: true

require "test_helper"

class ActiveMetrics::BucketTest < ActiveSupport::TestCase
  def setup
    @bucket = ActiveMetrics::Bucket.new
  end

  test "new bucket is empty" do
    bucket = ActiveMetrics::Bucket.new

    assert bucket.empty?
  end

  test "adding a count makes bucket non-empty" do
    @bucket.add("count", "requests", 1)

    assert_not @bucket.empty?
  end

  test "counts are summed per key" do
    @bucket.add("count", "requests", 1)
    @bucket.add("count", "requests", 2)
    @bucket.add("count", "requests", 3)

    assert_equal [ [ "count", "requests", 6.0 ] ], @bucket.drain
  end

  test "counts coerce values to floats" do
    @bucket.add("count", "requests", "5")

    assert_equal [ [ "count", "requests", 5.0 ] ], @bucket.drain
  end

  test "measures collect all values per key" do
    @bucket.add("measure", "db.query", 10)
    @bucket.add("measure", "db.query", 20)
    @bucket.add("measure", "db.query", 30)

    assert_equal [
      [ "measure", "db.query", 10.0 ],
      [ "measure", "db.query", 20.0 ],
      [ "measure", "db.query", 30.0 ]
    ], @bucket.drain
  end

  test "measures coerce values to floats" do
    @bucket.add("measure", "db.query", "15")

    assert_equal [ [ "measure", "db.query", 15.0 ] ], @bucket.drain
  end

  test "samples keep last value per key" do
    @bucket.add("sample", "queue.depth", 5)
    @bucket.add("sample", "queue.depth", 10)
    @bucket.add("sample", "queue.depth", 3)

    assert_equal [ [ "sample", "queue.depth", 3.0 ] ], @bucket.drain
  end

  test "samples coerce values to floats" do
    @bucket.add("sample", "queue.depth", "7")

    assert_equal [ [ "sample", "queue.depth", 7.0 ] ], @bucket.drain
  end

  test "metric type can be a symbol" do
    @bucket.add(:count, "requests", 1)
    @bucket.add(:measure, "timing", 50)
    @bucket.add(:sample, "gauge", 100)

    entries = @bucket.drain

    assert_includes entries, [ "count", "requests", 1.0 ]
    assert_includes entries, [ "measure", "timing", 50.0 ]
    assert_includes entries, [ "sample", "gauge", 100.0 ]
  end

  test "unknown metric types are ignored" do
    @bucket.add("unknown", "foo", 1)
    @bucket.add("invalid", "bar", 2)

    assert @bucket.empty?
  end

  test "clear resets the bucket" do
    @bucket.add("count", "requests", 5)
    @bucket.add("measure", "timing", 100)
    @bucket.add("sample", "gauge", 50)

    @bucket.clear

    assert @bucket.empty?
    assert_equal [], @bucket.drain
  end

  test "drain returns entries in insertion order" do
    @bucket.add("count", "c1", 1)
    @bucket.add("measure", "m1", 10)
    @bucket.add("sample", "s1", 100)

    types = @bucket.drain.map(&:first)

    assert_equal [ "count", "measure", "sample" ], types
  end

  test "multiple keys are tracked separately" do
    @bucket.add("count", "requests", 1)
    @bucket.add("count", "errors", 2)
    @bucket.add("measure", "db.read", 10)
    @bucket.add("measure", "db.write", 20)
    @bucket.add("sample", "memory", 100)
    @bucket.add("sample", "cpu", 50)

    assert_equal 6, @bucket.drain.size
  end

  test "drain returns entries and clears the bucket" do
    @bucket.add("count", "requests", 5)
    @bucket.add("measure", "timing", 100)

    result = @bucket.drain

    assert_equal [
      [ "count", "requests", 5.0 ],
      [ "measure", "timing", 100.0 ]
    ], result
    assert @bucket.empty?
  end

  test "drain on empty bucket returns empty array" do
    result = @bucket.drain

    assert_equal [], result
    assert @bucket.empty?
  end
end
