require_relative 'spec_helper'

RSpec.describe do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  it 'fails if command is nil' do
    expect { clazz.process(nil) }.to raise_error('command must not be empty')
  end

  it 'fails if command is empty' do
    expect { clazz.process('') }.to raise_error('command must not be empty')
  end
end
