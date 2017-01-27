require_relative 'spec_helper'

RSpec.describe 'trace handling' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  it 'prints command if trace is true' do
    expect do
      clazz.process('echo stdout > /dev/stdout', puts_output: :always, trace: true)
    end.to output("echo stdout > /dev/stdout\nstdout\n").to_stdout
        .and(not_output.to_stderr)
  end

  it 'does not print command if trace is false' do
    expect do
      clazz.process('echo stdout > /dev/stdout', puts_output: :always, trace: false)
    end.to output("stdout\n").to_stdout
        .and(not_output.to_stderr)
  end
end
