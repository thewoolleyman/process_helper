require_relative 'spec_helper'

RSpec.describe 'module visibility' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  it 'can be called as an included module' do
    expect do
      clazz.process('echo stdout > /dev/stdout')
    end.to output("stdout\n").to_stdout
  end

  it 'can be called as a module method' do
    expect do
      ProcessHelper.process('echo stdout > /dev/stdout')
    end.to output("stdout\n").to_stdout
  end

  it 'does not expose private methods' do
    expect(clazz.private_methods).to include(:process_with_popen)

    expect do
      clazz.process_with_popen
    end.to raise_error(NoMethodError)

    expect do
      ProcessHelper.process_with_popen
    end.to raise_error(NoMethodError)
  end
end
