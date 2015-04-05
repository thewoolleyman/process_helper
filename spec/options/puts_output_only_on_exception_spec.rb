require_relative '../spec_helper'

RSpec.describe ':puts_output_only_on_exception option' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  describe '== true (default)' do
    describe 'puts output to stdout if exception' do
      it 'when :expected_exit_status is zero' do
        expect do
          clazz.process('ls /does_not_exist', puts_output_only_on_exception: true)
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command failed/)
            .and(output("ls: /does_not_exist: No such file or directory\n").to_stdout)
      end

      it 'when :expected_exit_status is nonzero' do
        expect do
          clazz.process(
            'echo stdout > /dev/stdout',
            expected_exit_status: 1,
            puts_output_only_on_exception: true)
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command succeeded but was expected to fail/)
            .and(output("stdout\n").to_stdout)
      end
    end
  end

  describe '== false and :puts_output == false' do
    describe 'does not puts output to stdout if exception' do
      it 'when :expected_exit_status is zero' do
        expect do
          clazz.process(
            'ls /does_not_exist',
            puts_output: false,
            puts_output_only_on_exception: false)
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command failed/)
            .and(not_output.to_stdout)
      end

      it 'when :expected_exit_status is nonzero' do
        expect do
          clazz.process(
            'echo stdout > /dev/stdout',
            expected_exit_status: 1,
            puts_output: false,
            puts_output_only_on_exception: false)
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command succeeded but was expected to fail/)
            .and(not_output.to_stdout)
      end
    end
  end

  it 'fails if :puts_output is also explicitly set to true' do
    expect do
      clazz.process('ls', puts_output: true, puts_output_only_on_exception: true)
    end.to raise_error(
        ProcessHelper::InvalidOptionsError,
        "'puts_output' and 'puts_output_only_on_exception' options cannot both be true"
      )

  end
end
