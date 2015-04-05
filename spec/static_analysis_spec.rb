require_relative 'spec_helper'

describe 'static analysis checks' do
  include ProcessHelper

  it 'ruby-lint' do
    process(
      "ruby-lint #{File.expand_path('../../spec', __FILE__)}",
      puts_output: false,
      puts_output_only_on_exception: true
    )
  end

  it 'rubocop' do
    process('rubocop', puts_output: false, puts_output_only_on_exception: true)
  end
end
