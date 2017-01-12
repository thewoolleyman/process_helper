require_relative '../spec_helper'

RSpec.describe ':puts_output option' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  describe '== :always (default)' do
    it 'puts output to stdout' do
      expect do
        clazz.process('echo stdout > /dev/stdout', puts_output: :always)
      end.to output("stdout\n").to_stdout

      expect do
        clazz.process('echo stdout > /dev/stdout')
      end.to output("stdout\n").to_stdout
    end
  end

  describe '== :error' do
    describe 'when :expected_exit_status is zero' do
      it 'puts output to stdout on exception' do
        expect do
          clazz.process('ls /does_not_exist', puts_output: :error)
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command failed/)
            .and(output(/No such file or directory/).to_stdout)
      end

      it 'suppresses stdout if no exception' do
        expect do
          clazz.process('echo stdout > /dev/stdout', puts_output: :error)
        end.to not_output.to_stdout
            .and(not_output.to_stderr)
      end
    end

    describe 'when :expected_exit_status is nonzero' do
      it 'puts output to stdout on exception' do
        expect do
          clazz.process(
            'echo stdout > /dev/stdout',
            expected_exit_status: 1,
            puts_output: :error)
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command succeeded but was expected to fail/)
            .and(output("stdout\n").to_stdout)
      end

      it 'suppresses stdout if no exception' do
        expect do
          clazz.process(
            'ls /does_not_exist',
            expected_exit_status: [1, 2],
            puts_output: :error)
        end.to not_output.to_stdout
            .and(not_output.to_stderr)
      end
    end
  end

  describe '== :never' do
    it 'suppresses stdout' do
      expect do
        clazz.process(
          'echo stdout > /dev/stdout',
          puts_output: :never)
      end.to not_output.to_stdout
          .and(not_output.to_stderr)
    end
  end
end
