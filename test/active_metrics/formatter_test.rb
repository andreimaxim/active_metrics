# frozen_string_literal: true

require "test_helper"

class ActiveMetrics::FormatterTest < ActiveSupport::TestCase
  def setup
    @bucket = ActiveMetrics::Bucket.new
  end

  test "formats empty bucket as empty array" do
    formatter = ActiveMetrics::Formatter.new
    assert_equal [], formatter.format_lines(@bucket)
  end

  test "formats single count metric" do
    @bucket.add("count", "requests", 5)
    formatter = ActiveMetrics::Formatter.new

    lines = formatter.format_lines(@bucket)
    assert_equal ["count#requests=5.0"], lines
  end

  test "formats single measure metric" do
    @bucket.add("measure", "db.query", 12.5)
    formatter = ActiveMetrics::Formatter.new

    lines = formatter.format_lines(@bucket)
    assert_equal ["measure#db.query=12.5"], lines
  end

  test "formats single sample metric" do
    @bucket.add("sample", "queue.depth", 7)
    formatter = ActiveMetrics::Formatter.new

    lines = formatter.format_lines(@bucket)
    assert_equal ["sample#queue.depth=7.0"], lines
  end

  test "formats multiple metrics on one line" do
    @bucket.add("count", "requests", 8)
    @bucket.add("measure", "db.query", 12)
    @bucket.add("sample", "queue.depth", 7)
    formatter = ActiveMetrics::Formatter.new

    lines = formatter.format_lines(@bucket)
    assert_equal 1, lines.size
    assert_equal "count#requests=8.0 measure#db.query=12.0 sample#queue.depth=7.0", lines.first
  end

  test "includes source prefix when configured" do
    @bucket.add("count", "requests", 5)
    formatter = ActiveMetrics::Formatter.new(source: "web.1")

    lines = formatter.format_lines(@bucket)
    assert_equal ["source=web.1 count#requests=5.0"], lines
  end

  test "splits lines when exceeding max_line_length" do
    @bucket.add("count", "metric.one", 1)
    @bucket.add("count", "metric.two", 2)
    @bucket.add("count", "metric.three", 3)
    formatter = ActiveMetrics::Formatter.new(max_line_length: 50)

    lines = formatter.format_lines(@bucket)
    assert_operator lines.size, :>, 1
    lines.each do |line|
      assert_operator line.bytesize, :<=, 50
    end
  end

  test "splits lines with source prefix" do
    @bucket.add("count", "metric.one", 1)
    @bucket.add("count", "metric.two", 2)
    @bucket.add("count", "metric.three", 3)
    formatter = ActiveMetrics::Formatter.new(source: "web.1", max_line_length: 60)

    lines = formatter.format_lines(@bucket)
    assert_operator lines.size, :>, 1
    lines.each do |line|
      assert line.start_with?("source=web.1 "), "Line should start with source prefix: #{line}"
    end
  end

  test "single token exceeding max_line_length is emitted on its own line" do
    @bucket.add("count", "very.long.metric.name.that.exceeds.limit", 1)
    formatter = ActiveMetrics::Formatter.new(max_line_length: 20)

    lines = formatter.format_lines(@bucket)
    assert_equal 1, lines.size
  end

  test "uses bytesize not length for line splitting" do
    @bucket.add("count", "metric", 1)
    @bucket.add("count", "données", 2)  # UTF-8 characters
    formatter = ActiveMetrics::Formatter.new(max_line_length: 50)

    lines = formatter.format_lines(@bucket)
    lines.each do |line|
      assert_operator line.bytesize, :<=, 50
    end
  end

  test "default max_line_length is 1024" do
    formatter = ActiveMetrics::Formatter.new
    100.times { |i| @bucket.add("count", "metric#{i}", i) }

    lines = formatter.format_lines(@bucket)
    lines.each do |line|
      assert_operator line.bytesize, :<=, 1024
    end
  end
end
