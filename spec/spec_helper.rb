if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'rspec'
require_relative '../lib/process_helper'

RSpec::Matchers.define_negated_matcher :not_output, :output
RSpec::Matchers.define_negated_matcher :not_raise_error, :raise_error

# RSpec config
# RSpec.configure do |c|
# end

# RSpec helper methods
# module SpecHelper
# end
# include SpecHelper

# Dummy fixture class
class Clazz
  include ProcessHelper
end
