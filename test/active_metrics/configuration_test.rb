# frozen_string_literal: true

require "test_helper"

class ActiveMetrics::ConfigurationTest < ActiveSupport::TestCase
  def setup
    @config = ActiveMetrics::Configuration.new
  end

  test "default batching_mode is :immediate" do
    assert_equal :immediate, @config.batching_mode
  end

  test "default interval is 5.0" do
    assert_equal 5.0, @config.interval
  end

  test "default max_buffer_size is 10_000" do
    assert_equal 10_000, @config.max_buffer_size
  end

  test "default overflow_policy is :drop_newest" do
    assert_equal :drop_newest, @config.overflow_policy
  end

  test "default max_line_length is 1024" do
    assert_equal 1024, @config.max_line_length
  end

  test "batching_mode is writable" do
    @config.batching_mode = :interval
    assert_equal :interval, @config.batching_mode
  end

  test "interval is writable" do
    @config.interval = 10.0
    assert_equal 10.0, @config.interval
  end

  test "max_buffer_size is writable" do
    @config.max_buffer_size = 5_000
    assert_equal 5_000, @config.max_buffer_size
  end

  test "overflow_policy is writable" do
    @config.overflow_policy = :drop_oldest
    assert_equal :drop_oldest, @config.overflow_policy
  end

  test "max_line_length is writable" do
    @config.max_line_length = 2048
    assert_equal 2048, @config.max_line_length
  end
end
