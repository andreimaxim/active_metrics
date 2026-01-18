# frozen_string_literal: true

require "test_helper"

class ActiveMetricsTest < ActiveSupport::TestCase
  test "has a version number" do
    refute_nil ::ActiveMetrics::VERSION
  end

  test "setup works without a block" do
    assert_nothing_raised do
      ActiveMetrics.setup
    end
  end

  test "setup works with a block" do
    assert_nothing_raised do
      ActiveMetrics.setup do
        interval 10.0
      end
    end
  end
end
