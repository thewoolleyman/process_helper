require_relative 'spec_helper'

RSpec.describe do
  it 'has a version number' do
    expect(::ProcessHelper::VERSION).to match(/^\d\.\d\.\d\.*\w*$/)
  end
end
