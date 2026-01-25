# frozen_string_literal: true

require "test_helper"

class ActiveMetrics::InstrumentableTest < ActiveSupport::TestCase
  class TestClass
    include ActiveMetrics::Instrumentable
  end

  def setup
    @output = []
    $stdout.stubs(:puts).with { |line| @output << line }
    @config = ActiveMetrics::Configuration.new
    @config.batching_mode = :immediate
    @config.silent = false
    ActiveMetrics.stubs(:config).returns(@config)
    ActiveMetrics.reset_collector!
    @subscriber = ActiveMetrics.collector.attach
    @subject = TestClass.new
  end

  def teardown
    ActiveSupport::Notifications.unsubscribe(@subscriber)
  end

  test "count records a count metric with default value of 1" do
    @subject.count("requests")

    assert_includes @output.join, "count#requests=1"
  end

  test "count records a count metric with custom value" do
    @subject.count("requests", 5)

    assert_includes @output.join, "count#requests=5"
  end

  test "measure records a measure metric with explicit value" do
    @subject.measure("response_time", 150)

    assert_includes @output.join, "measure#response_time=150"
  end

  test "measure with block measures elapsed time" do
    @subject.measure("slow_operation") { sleep(0.01) }

    assert_match(/measure#slow_operation=0\.0\d+/, @output.join)
  end

  test "measure with block returns the block value" do
    result = @subject.measure("computation") { 42 }

    assert_equal 42, result
  end

  test "measure without block uses default value of 0" do
    @subject.measure("empty")

    assert_includes @output.join, "measure#empty=0"
  end

  test "sample records a sample metric" do
    @subject.sample("memory_usage", 1024)

    assert_includes @output.join, "sample#memory_usage=1024"
  end

  test "sample records a sample metric with string value" do
    @subject.sample("version", "3.2.1")

    assert_includes @output.join, "sample#version=3.2"
  end
end
