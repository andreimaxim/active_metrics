if ENV['ENV'] == 'test'
  require 'simplecov'
  SimpleCov.start 'rails'
  puts 'required simplecov'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_metrics'

require 'minitest/autorun'
