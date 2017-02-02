require_relative 'spec_helper'

RSpec.describe 'log command handling' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  it 'prints command if log_cmd is true' do
    expect do
      clazz.process('echo stdout > /dev/stdout', puts_output: :always, log_cmd: true)
    end.to output("echo stdout > /dev/stdout\nstdout\n").to_stdout
        .and(not_output.to_stderr)
  end

  it 'does not print command if log_cmd is false' do
    expect do
      clazz.process('echo stdout > /dev/stdout', puts_output: :always, log_cmd: false)
    end.to output("stdout\n").to_stdout
        .and(not_output.to_stderr)
  end
end
