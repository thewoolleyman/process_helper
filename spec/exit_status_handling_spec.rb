require_relative 'spec_helper'

RSpec.describe 'exit status handling' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  describe ':expected_exit_status == 0' do
    describe 'when exit_status == 0' do
      it 'succeeds' do
        expect do
          clazz.process('echo')
        end.to not_raise_error
            .and(output("\n").to_stdout)
      end
    end

    describe 'when exit_status != 0' do
      it 'fails with message' do
        # rubocop:disable Metrics/LineLength
        cmd_regex = Regexp.escape('`ls /does_not_exist`')
        expect do
          clazz.process('ls /does_not_exist', puts_output: :exception)
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command failed, pid \d+ exit 1\. Command: #{cmd_regex}\./
          )
            .and(output(/No such file or directory/).to_stdout)
      end
    end
  end

  describe ':expected_exit_status != 0' do
    describe 'when exit_status == 0' do
      it 'fails with message' do
        # rubocop:disable Metrics/LineLength
        expect do
          clazz.process('echo', expected_exit_status: 1, puts_output: :exception)
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command succeeded but was expected to fail, pid \d+ exit 0 \(expected 1\). Command: #{Regexp.escape('`echo`')}\./
          )
            .and(output("\n").to_stdout)
      end
    end
    describe 'when exit_status != 0' do
      it 'succeeds' do
        expect do
          clazz.process('ls /does_not_exist', expected_exit_status: 1, puts_output: :exception)
        end.to_not raise_error
      end
    end
  end
end
