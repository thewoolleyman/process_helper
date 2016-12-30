SimpleCov.start if ENV['CI']

require 'rspec'
require 'rspec/retry'
require_relative '../lib/process_helper'

RSpec::Matchers.define_negated_matcher :not_output, :output
RSpec::Matchers.define_negated_matcher :not_raise_error, :raise_error

# RSpec config
RSpec.configure do |config|
  config.verbose_retry = true
  config.default_retry_count = 5
  config.default_sleep_interval = 1
end

# RSpec helper methods
# module SpecHelper
# end
# include SpecHelper

# Dummy fixture class
class Clazz
  include ProcessHelper
end
