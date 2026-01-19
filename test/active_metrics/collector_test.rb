# frozen_string_literal: true

require "test_helper"

class ActiveMetrics::CollectorTest < ActiveSupport::TestCase
  def setup
    @output = []
    $stdout.stubs(:puts).with { |line| @output << line }
    @config = ActiveMetrics::Configuration.new

    ActiveMetrics.stubs(:config).returns(@config)
    ActiveMetrics.stubs(:collector).returns(ActiveMetrics::Collector.new)

    @subscriber = ActiveMetrics.collector.attach
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

    output = @output.join
    assert_includes output, "count#requests=5.0"
    assert_includes output, "count#other=1.0"
  end

  test "interval mode flushes automatically without new events" do
    skip "pending background flush implementation"

    @config.batching_mode = :interval
    @config.interval = 0.01
    @config.silent = false

    ActiveMetrics::Collector.record("requests", metric: "count", value: 5)

    assert_empty @output

    sleep(0.02)

    assert_includes @output.join, "count#requests=5.0"
  end

  test "flush outputs buffered metrics" do
    @config.batching_mode = :interval
    @config.interval = 60.0
    @config.silent = false

    ActiveMetrics::Collector.record("requests", metric: "count", value: 5)
    ActiveMetrics::Collector.record("db.query", metric: "measure", value: 12)

    assert_empty @output

    ActiveMetrics.collector.flush

    output = @output.join
    assert_includes output, "count#requests=5.0"
    assert_includes output, "measure#db.query=12.0"
  end

  test "flush does nothing when bucket is empty" do
    @config.batching_mode = :interval
    @config.silent = false

    ActiveMetrics.collector.flush

    assert_empty @output
  end

  test "flush clears the bucket" do
    @config.batching_mode = :interval
    @config.interval = 60.0
    @config.silent = false

    ActiveMetrics::Collector.record("requests", metric: "count", value: 5)
    ActiveMetrics.collector.flush

    @output.clear

    ActiveMetrics.collector.flush

    assert_empty @output
  end

  test "deliver strips the ActiveMetrics prefix from the event name" do
    @config.batching_mode = :immediate
    @config.silent = false

    prefix = ActiveMetrics::Collector::PREFIX
    ActiveMetrics.collector.deliver("#{prefix}user.login", metric: "count", value: 1)

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

  test "class method attach delegates to collector instance" do
    ActiveSupport::Notifications.unsubscribe(@subscriber)

    collector = ActiveMetrics::Collector.new
    ActiveMetrics.stubs(:collector).returns(collector)

    subscriber = ActiveMetrics::Collector.attach

    assert_not_nil subscriber
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
