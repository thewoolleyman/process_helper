require_relative 'spec_helper'

RSpec.describe 'version' do
  it 'is semantic' do
    expect(::ProcessHelper::PROCESS_HELPER_VERSION).to match(/^\d\.\d\.\d\.*\w*$/)
  end
end
