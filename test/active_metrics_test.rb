require 'test_helper'

class ActiveMetricsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ActiveMetrics::VERSION
  end
end
