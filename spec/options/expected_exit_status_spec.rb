require_relative '../spec_helper'

RSpec.describe ':expected_exit_status option' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  describe '== 0 (default)' do
    describe 'when exit_status == 0' do
      it 'succeeds' do
        expect do
          clazz.process('echo')
        end.to not_raise_error
            .and(output("\n").to_stdout)
      end

      it 'succeeds when :expected_exit_status is explicitly 0' do
        expect do
          clazz.process('echo', exp_st: 0)
        end.to not_raise_error
            .and(output("\n").to_stdout)
      end

    end

    describe 'when exit_status != 0' do
      it 'fails with message' do
        cmd_regex = Regexp.escape('`ls /does_not_exist`')
        expect do
          clazz.process('ls /does_not_exist', puts_output: :error)
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command failed, pid \d+ exit 1\. Command: #{cmd_regex}\./
          )
            .and(output(/No such file or directory/).to_stdout)
      end
    end
  end

  describe '!= 0' do
    describe 'when exit_status == 0' do
      it 'fails with message' do
        expected_regex = 'Command succeeded but was expected to fail, ' \
          'pid \d+ exit 0 \(expected 1\). Command: ' \
          "#{Regexp.escape('`echo`')}" \
          '\.'
        expect do
          clazz.process('echo', exp_st: 1, puts_output: :error)
        end.to raise_error(ProcessHelper::UnexpectedExitStatusError, /#{expected_regex}/)
            .and(output("\n").to_stdout)
      end
    end

    describe 'when exit_status != 0' do
      it 'succeeds' do
        expect do
          clazz.process('ls /does_not_exist', exp_st: 1, puts_output: :error)
        end.to_not raise_error
      end
    end
  end

  it 'supports long form of option' do
    expect do
      clazz.process('echo', expected_exit_status: 0)
    end.to not_raise_error
        .and(output("\n").to_stdout)
  end
end
