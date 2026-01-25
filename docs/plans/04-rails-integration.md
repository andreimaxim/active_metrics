# Plan 4: Rails Integration

## Goal

Add `:request` batching mode that collects all metrics emitted during a Rails request and flushes them at the end of the request. Uses thread-local storage and Rails lifecycle events.

## Prerequisites

- Plan 1 (Configuration) must be complete
- Plan 2 (Interval Batching) must be complete
- Plan 3 (Thread-Safe Batching) must be complete

## Files to Create/Modify

| File | Action |
|------|--------|
| `lib/active_metrics/batcher.rb` | MODIFY - add request mode support |
| `lib/active_metrics/railtie.rb` | CREATE - Rails auto-integration |
| `lib/active_metrics.rb` | MODIFY - require railtie when Rails defined |

## Request Mode in Batcher

Add thread-local buffer storage and request lifecycle methods:

```ruby
# Add to Batcher class

THREAD_BUFFER_KEY = :active_metrics_buffer

def record(metric:, key:, value:)
  return if Collector.silent?
  return if @shutdown.value

  case ActiveMetrics.config.batching_mode
  when :immediate
    write_immediate(metric, key, value)
  when :interval
    enqueue_interval(metric, key, value)
  when :request
    record_request(metric, key, value)
  end
end

def flush
  case ActiveMetrics.config.batching_mode
  when :interval then flush_interval
  when :request  then flush_request_buffer
  end
end

# --- Request Mode (public for Rails hooks) ---

def clear_request_buffer
  Thread.current[THREAD_BUFFER_KEY]&.clear
end

def flush_request_buffer
  buffer = Thread.current[THREAD_BUFFER_KEY]
  return if buffer.nil? || buffer.empty?
  write_buffer(buffer)
  buffer.clear
end

private

def record_request(metric, key, value)
  buffer = Thread.current[THREAD_BUFFER_KEY] ||= Buffer.new

  max = ActiveMetrics.config.max_buffer_size
  if max > 0 && buffer.event_count >= max
    case ActiveMetrics.config.overflow_policy
    when :drop_newest
      return
    when :flush, :drop_oldest
      flush_request_buffer
    end
  end

  buffer.add(metric, key, value)
end
```

## Railtie

```ruby
# lib/active_metrics/railtie.rb

begin
  require "rails/railtie"
rescue LoadError
  # Rails not installed; skip
  return
end

module ActiveMetrics
  class Railtie < Rails::Railtie
    initializer "active_metrics.setup" do
      # Auto-attach collector in Rails apps
      ActiveMetrics::Collector.attach

      # Request lifecycle hooks (only active when mode is :request)
      ActiveSupport::Notifications.subscribe("start_processing.action_controller") do |*|
        if ActiveMetrics.config.batching_mode == :request
          ActiveMetrics::Batcher.instance.clear_request_buffer
        end
      end

      ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*|
        if ActiveMetrics.config.batching_mode == :request
          ActiveMetrics::Batcher.instance.flush_request_buffer
        end
      end
    end
  end
end
```

## Main Entry Point Update

```ruby
# lib/active_metrics.rb

# At the end, after other requires:
require "active_metrics/railtie" if defined?(Rails::Railtie)
```

## Rails Request Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                        Rails Request                            │
├─────────────────────────────────────────────────────────────────┤
│  1. start_processing.action_controller                          │
│     └── clear_request_buffer (prevents leakage from prior req)  │
│                                                                 │
│  2. Controller action runs                                      │
│     └── count/measure/sample → thread-local Buffer              │
│                                                                 │
│  3. process_action.action_controller                            │
│     └── flush_request_buffer → aggregated output to stdout      │
└─────────────────────────────────────────────────────────────────┘
```

## Thread-Local Storage

| Approach | Pros | Cons |
|----------|------|------|
| `Thread.current[...]` | Simple, works everywhere | Not fiber-safe |
| `ActiveSupport::IsolatedExecutionState` | Fiber-safe (Rails 7+) | Only available in newer Rails |

**Initial implementation**: Use `Thread.current[...]` for broad compatibility.

**Future enhancement**: Detect and use `IsolatedExecutionState` when available:

```ruby
def request_buffer
  if defined?(ActiveSupport::IsolatedExecutionState)
    ActiveSupport::IsolatedExecutionState[THREAD_BUFFER_KEY] ||= Buffer.new
  else
    Thread.current[THREAD_BUFFER_KEY] ||= Buffer.new
  end
end
```

## Overflow Policies (Request Mode)

| Policy | Behavior |
|--------|----------|
| `:drop_newest` | Discard new event when buffer full |
| `:drop_oldest` | Flush buffer (simpler than true drop-oldest), accept new |
| `:flush` | Flush buffer, accept new |

Note: True `:drop_oldest` would require removing aggregated data from Buffer, which is complex (can't un-sum a count). Flushing mid-request is the pragmatic fallback.

## Configuration Example

```ruby
# config/initializers/active_metrics.rb

ActiveMetrics.configure do |c|
  c.batching_mode   = :request
  c.max_buffer_size = 1_000
  c.overflow_policy = :flush
  c.source          = ENV["DYNO"]
end
```

## Output Example

At end of each request, one log line (or multiple if exceeds max_line_length):

```
source=web.1 count#user.login=1 count#api.call=3 measure#db.query=0.012 measure#db.query=0.008 sample#memory.used=142857
```

## Testing

- **Request mode isolation**: Metrics from one thread don't leak to another
- **Clear on start**: Buffer is empty at request start
- **Flush on end**: Buffer contents output after `process_action`
- **Overflow handling**: Each policy works correctly
- **Railtie loading**: Only loads when Rails is defined
- **Non-Rails apps**: Request mode still works with manual `clear`/`flush` calls

## Edge Cases & Risks

| Risk | Mitigation |
|------|------------|
| Exception before `process_action` | `clear_request_buffer` at start prevents stale data |
| Streaming responses | Metrics flush at action end, before streaming body |
| Background jobs (Sidekiq) | Works fine—each job runs in its own thread context |
| Fiber-based concurrency | Future: use `IsolatedExecutionState` |
| Puma clustered mode | Thread-local per worker, no issues |

## Future Considerations (Out of Scope)

- **Rack middleware fallback**: For apps without ActionController
- **Per-request correlation IDs**: Add request ID to output line
- **Automatic source detection**: Infer from `ENV["DYNO"]` or similar

## Estimated Effort

**M (1-2 hours)** including tests
