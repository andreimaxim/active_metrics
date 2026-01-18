# frozen_string_literal: true

require "test_helper"

class ActiveMetrics::CollectorTest < ActiveSupport::TestCase
  def setup
    @output = []
    $stdout.stubs(:puts).with { |line| @output << line }
    @config = ActiveMetrics::Configuration.new

    ActiveMetrics::Collector.stubs(:bucket).returns(ActiveMetrics::Bucket.new)
    ActiveMetrics.stubs(:config).returns(@config)

    @subscriber = ActiveMetrics::Collector.attach
  end

  def teardown
    ActiveSupport::Notifications.unsubscribe(@subscriber)
  end

  test "immediate mode outputs metric directly" do
    @config.batching_mode = :immediate
    @config.silent = false

    ActiveMetrics::Collector.record("requests", metric: "count", value: 5)

    assert_equal [ "count#requests=5" ], @output
  end

  test "silent mode suppresses output" do
    @config.batching_mode = :immediate
    @config.silent = true

    ActiveMetrics::Collector.record("requests", metric: "count", value: 5)

    assert_empty @output
  end

  # Interval mode tests

  test "interval mode buffers metrics" do
    @config.batching_mode = :interval
    @config.interval = 60.0
    @config.silent = false

    ActiveMetrics::Collector.record("requests", metric: "count", value: 5)

    assert_empty @output
  end

  test "interval mode flushes when interval elapsed" do
    @config.batching_mode = :interval
    @config.interval = 0.001
    @config.silent = false

    ActiveMetrics::Collector.record("requests", metric: "count", value: 5)
    sleep(0.002)
    ActiveMetrics::Collector.record("other", metric: "count", value: 1)

    assert_includes @output.join, "count#requests=5.0"
  end

  test "flush outputs buffered metrics" do
    @config.batching_mode = :interval
    @config.interval = 60.0
    @config.silent = false

    ActiveMetrics::Collector.record("requests", metric: "count", value: 5)
    ActiveMetrics::Collector.record("db.query", metric: "measure", value: 12)

    assert_empty @output

    ActiveMetrics::Collector.flush

    output = @output.join
    assert_includes output, "count#requests=5.0"
    assert_includes output, "measure#db.query=12.0"
  end

  test "flush does nothing when bucket is empty" do
    @config.batching_mode = :interval
    @config.silent = false

    ActiveMetrics::Collector.flush

    assert_empty @output
  end

  test "flush clears the bucket" do
    @config.batching_mode = :interval
    @config.interval = 60.0
    @config.silent = false

    ActiveMetrics::Collector.record("requests", metric: "count", value: 5)
    ActiveMetrics::Collector.flush

    @output.clear

    ActiveMetrics::Collector.flush

    assert_empty @output
  end

  test "overflow triggers flush when max_buffer_size reached" do
    @config.batching_mode = :interval
    @config.interval = 60.0
    @config.max_buffer_size = 3
    @config.silent = false

    ActiveMetrics::Collector.record("m1", metric: "count", value: 1)
    ActiveMetrics::Collector.record("m2", metric: "count", value: 2)

    assert_empty @output

    ActiveMetrics::Collector.record("m3", metric: "count", value: 3)

    assert_not_empty @output
  end

  test "deliver strips the ActiveMetrics prefix from the event name" do
    @config.batching_mode = :immediate
    @config.silent = false

    prefix = ActiveMetrics::Collector::PREFIX
    ActiveMetrics::Collector.deliver("#{prefix}user.login", metric: "count", value: 1)

    assert_equal [ "count#user.login=1" ], @output
  end

  test "record instruments via ActiveSupport::Notifications" do
    events = []
    ActiveSupport::Notifications.subscribe(/com.active_metrics/) do |name, _, _, _, data|
      events << { name: name, data: data }
    end

    ActiveMetrics::Collector.record("test.event", metric: "count", value: 1)

    assert_equal 1, events.size
    assert_equal "com.active_metricstest.event", events.first[:name]
  end

  test "record with block instruments the block" do
    events = []
    ActiveSupport::Notifications.subscribe(/com.active_metrics/) do |name, start, finish, _, data|
      events << { name: name, duration: finish - start }
    end

    result = ActiveMetrics::Collector.record("test.event", metric: "measure") { sleep(0.01); 42 }

    assert_equal 42, result
    assert_equal 1, events.size
    assert_operator events.first[:duration], :>=, 0.01
  end

  test "attach subscribes to ActiveSupport::Notifications" do
    @config.batching_mode = :immediate
    @config.silent = false

    ActiveSupport::Notifications.instrument("com.active_metrics.attached", metric: "count", value: 1)

    assert_equal [ "count#.attached=1" ], @output
  end
end
