if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
  end
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "active_metrics"

require "active_support"
require "active_support/test_case"
require "minitest/autorun"
