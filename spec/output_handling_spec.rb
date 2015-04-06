require_relative 'spec_helper'

RSpec.describe 'output handling' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  it 'captures stdout only' do
    expect do
      clazz.process(
        'echo stdout > /dev/stdout && echo stderr > /dev/null',
        puts_output: :always)
    end.to output("stdout\n").to_stdout
        .and(not_output.to_stderr)
  end

  it 'captures stderr only' do
    expect do
      clazz.process(
        'echo stdout > /dev/null && echo stderr > /dev/stderr',
        puts_output: :always)
    end.to output("stderr\n").to_stdout
        .and(not_output.to_stderr)
  end

  it 'captures stdout and stderr' do
    expect do
      clazz.process(
        'echo stdout > /dev/stdout && echo stderr > /dev/stderr',
        puts_output: :always)
    end.to output("stdout\nstderr\n").to_stdout
        .and(not_output.to_stderr)
  end

  describe 'when :puts_output == :never' do
    describe 'when include_output_in_exception is false' do
      it 'show warning' do
        expect do
          clazz.process(
            'echo stdout > /dev/stdout',
            puts_output: :never,
            include_output_in_exception: false)
        end.to output(/all error output will be suppressed if process fails/).to_stderr
            .and(not_output.to_stdout)
      end
    end

    describe 'when include_output_in_exception == true' do
      it 'do not show warning' do
        expect do
          clazz.process(
            'echo stdout > /dev/stdout',
            puts_output: :never)
        end.to output(/unless process fails with an exit code other than \[0\]/).to_stderr
            .and(not_output.to_stdout)
      end
    end
  end
end
