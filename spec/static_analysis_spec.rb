require_relative 'spec_helper'

describe 'static analysis checks' do
  include ProcessHelper

  it 'ruby-lint' do
    process(
      "ruby-lint #{File.expand_path('../../spec', __FILE__)}",
      puts_output: :exception
    )
  end

  it 'rubocop' do
    process('rubocop', puts_output: :exception)
  end
end
