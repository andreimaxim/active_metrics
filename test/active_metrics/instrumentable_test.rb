# frozen_string_literal: true

require "test_helper"

class ActiveMetrics::InstrumentableTest < ActiveSupport::TestCase
  class TestClass
    include ActiveMetrics::Instrumentable
  end

  def setup
    @original_stdout = $stdout
    $stdout = StringIO.new
    ActiveMetrics::Collector.reset
    ActiveSupport::Notifications.unsubscribe(/com.active_metrics/)
    @subject = TestClass.new
  end

  def teardown
    $stdout = @original_stdout
    ActiveMetrics::Collector.reset
    ActiveMetrics.instance_variable_set(:@config, nil)
    ActiveSupport::Notifications.unsubscribe(/com.active_metrics/)
  end

  # count tests

  test "count records a count metric with default value of 1" do
    with_immediate_mode do
      @subject.count("requests")

      assert_includes $stdout.string, "count#requests=1"
    end
  end

  test "count records a count metric with custom value" do
    with_immediate_mode do
      @subject.count("requests", 5)

      assert_includes $stdout.string, "count#requests=5"
    end
  end

  # measure tests

  test "measure records a measure metric with explicit value" do
    with_immediate_mode do
      @subject.measure("response_time", 150)

      assert_includes $stdout.string, "measure#response_time=150"
    end
  end

  test "measure with block measures elapsed time" do
    with_immediate_mode do
      @subject.measure("slow_operation") { sleep(0.01) }

      assert_match(/measure#slow_operation=0\.0\d+/, $stdout.string)
    end
  end

  test "measure with block returns the block value" do
    with_immediate_mode do
      result = @subject.measure("computation") { 42 }

      assert_equal 42, result
    end
  end

  test "measure without block uses default value of 0" do
    with_immediate_mode do
      @subject.measure("empty")

      assert_includes $stdout.string, "measure#empty=0"
    end
  end

  # sample tests

  test "sample records a sample metric" do
    with_immediate_mode do
      @subject.sample("memory_usage", 1024)

      assert_includes $stdout.string, "sample#memory_usage=1024"
    end
  end

  test "sample records a sample metric with string value" do
    with_immediate_mode do
      @subject.sample("version", "1.0.0")

      assert_includes $stdout.string, "sample#version=1.0.0"
    end
  end

  private

  def with_immediate_mode
    ActiveMetrics.setup { |c| c.batching_mode = :immediate; c.silent = false }
    ActiveMetrics::Collector.attach
    yield
  ensure
    ActiveSupport::Notifications.unsubscribe(/com.active_metrics/)
  end
end
