require 'rspec'
require_relative '../lib/process_helper'

RSpec::Matchers.define_negated_matcher :not_output, :output

# RSpec config
# RSpec.configure do |c|
# end

# RSpec helper methods
# module SpecHelper
# end
# include SpecHelper

