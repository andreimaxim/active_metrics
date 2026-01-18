# frozen_string_literal: true

require "test_helper"

class ActiveMetrics::CollectorTest < ActiveSupport::TestCase
  def setup
    @original_stdout = $stdout
    $stdout = StringIO.new
    ActiveMetrics::Collector.reset
  end

  def teardown
    $stdout = @original_stdout
    ActiveMetrics::Collector.reset
    # Reset config by clearing the instance variable
    ActiveMetrics.instance_variable_set(:@config, nil)
  end

  # Immediate mode tests (default)

  test "immediate mode outputs metric directly" do
    with_config(batching_mode: :immediate, silent: false) do
      ActiveMetrics::Collector.deliver("com.active_metrics.requests", { metric: "count", value: 5 })

      assert_equal "count#.requests=5\n", $stdout.string
    end
  end

  test "silent mode suppresses output" do
    with_config(batching_mode: :immediate, silent: true) do
      ActiveMetrics::Collector.deliver("com.active_metrics.requests", { metric: "count", value: 5 })

      assert_empty $stdout.string
    end
  end

  # Interval mode tests

  test "interval mode buffers metrics" do
    with_config(batching_mode: :interval, interval: 60.0, silent: false) do
      ActiveMetrics::Collector.deliver("com.active_metrics.requests", { metric: "count", value: 5 })

      assert_empty $stdout.string
    end
  end

  test "interval mode flushes when interval elapsed" do
    with_config(batching_mode: :interval, interval: 0.001, silent: false) do
      ActiveMetrics::Collector.deliver("com.active_metrics.requests", { metric: "count", value: 5 })
      sleep(0.002)
      ActiveMetrics::Collector.deliver("com.active_metrics.other", { metric: "count", value: 1 })

      assert_includes $stdout.string, "count#.requests=5.0"
    end
  end

  test "flush outputs buffered metrics" do
    with_config(batching_mode: :interval, interval: 60.0, silent: false) do
      ActiveMetrics::Collector.deliver("com.active_metrics.requests", { metric: "count", value: 5 })
      ActiveMetrics::Collector.deliver("com.active_metrics.db.query", { metric: "measure", value: 12 })

      assert_empty $stdout.string

      ActiveMetrics::Collector.flush

      assert_includes $stdout.string, "count#.requests=5.0"
      assert_includes $stdout.string, "measure#.db.query=12.0"
    end
  end

  test "flush does nothing when bucket is empty" do
    with_config(batching_mode: :interval, silent: false) do
      ActiveMetrics::Collector.flush

      assert_empty $stdout.string
    end
  end

  test "flush clears the bucket" do
    with_config(batching_mode: :interval, interval: 60.0, silent: false) do
      ActiveMetrics::Collector.deliver("com.active_metrics.requests", { metric: "count", value: 5 })
      ActiveMetrics::Collector.flush

      $stdout.truncate(0)
      $stdout.rewind

      ActiveMetrics::Collector.flush

      assert_empty $stdout.string
    end
  end

  test "overflow triggers flush when max_buffer_size reached" do
    with_config(batching_mode: :interval, interval: 60.0, max_buffer_size: 3, silent: false) do
      ActiveMetrics::Collector.deliver("com.active_metrics.m1", { metric: "count", value: 1 })
      ActiveMetrics::Collector.deliver("com.active_metrics.m2", { metric: "count", value: 2 })

      assert_empty $stdout.string

      ActiveMetrics::Collector.deliver("com.active_metrics.m3", { metric: "count", value: 3 })

      refute_empty $stdout.string
    end
  end

  test "key extraction removes prefix correctly" do
    with_config(batching_mode: :immediate, silent: false) do
      ActiveMetrics::Collector.deliver("com.active_metrics.user.login", { metric: "count", value: 1 })

      assert_includes $stdout.string, "count#.user.login=1"
    end
  end

  test "record instruments via ActiveSupport::Notifications" do
    events = []
    ActiveSupport::Notifications.subscribe(/com.active_metrics/) do |name, _, _, _, data|
      events << { name: name, data: data }
    end

    ActiveMetrics::Collector.record(".test.event", { metric: "count", value: 1 })

    assert_equal 1, events.size
    assert_equal "com.active_metrics.test.event", events.first[:name]
  ensure
    ActiveSupport::Notifications.unsubscribe(/com.active_metrics/)
  end

  test "record with block instruments the block" do
    events = []
    ActiveSupport::Notifications.subscribe(/com.active_metrics/) do |name, start, finish, _, data|
      events << { name: name, duration: finish - start }
    end

    result = ActiveMetrics::Collector.record(".test.event", { metric: "measure" }) { sleep(0.01); 42 }

    assert_equal 42, result
    assert_equal 1, events.size
    assert_operator events.first[:duration], :>=, 0.01
  ensure
    ActiveSupport::Notifications.unsubscribe(/com.active_metrics/)
  end

  test "attach subscribes to ActiveSupport::Notifications" do
    with_config(batching_mode: :immediate, silent: false) do
      ActiveMetrics::Collector.attach
      ActiveSupport::Notifications.instrument("com.active_metrics.attached", { metric: "count", value: 1 })

      assert_includes $stdout.string, "count#.attached=1"
    end
  ensure
    ActiveSupport::Notifications.unsubscribe(/com.active_metrics/)
  end

  private

  def with_config(**options)
    ActiveMetrics.setup do |config|
      options.each { |key, value| config.public_send("#{key}=", value) }
    end
    yield
  end
end
