require_relative 'spec_helper'

RSpec.describe do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  it 'captures stdout only' do
    output = clazz.process(
      'echo stdout > /dev/stdout && echo stderr > /dev/null',
      puts_output: false)
    expect(output).to eq("stdout\n")
  end

  it 'captures stderr only' do
    output = clazz.process(
      'echo stdout > /dev/null && echo stderr > /dev/stderr',
      puts_output: false)
    expect(output).to eq("stderr\n")
  end

  it 'captures stdout and stderr' do
    output = clazz.process(
      'echo stdout > /dev/stdout && echo stderr > /dev/stderr',
      puts_output: false)
    expect(output).to eq("stdout\nstderr\n")
  end
end
