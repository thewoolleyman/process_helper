require_relative 'spec_helper'

RSpec.describe 'version' do
  it 'is semantic' do
    expect(::ProcessHelper::VERSION).to match(/^\d\.\d\.\d\.*\w*$/)
  end
end
