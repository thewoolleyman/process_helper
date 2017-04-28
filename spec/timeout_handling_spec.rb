require_relative 'spec_helper'

RSpec.describe 'timout handling with non-exiting blocking cmd requiring timeout' do
  attr_reader :clazz, :max_process_wait

  before do
    @clazz = Clazz.new
    @max_process_wait = ENV['MAX_PROCESS_WAIT'] ? ENV['MAX_PROCESS_WAIT'].to_f : 0.5
  end

  # TODO: ensure every place that can raise a timeout is specifically exercised by a test

  it 'raises on a sleep' do
    expect do
      clazz.process(
        'sleep 999',
        timeout: max_process_wait
      )
    end.to raise_error(
      ProcessHelper::TimeoutError,
      "Timed out after #{@max_process_wait} seconds. Command output prior to timeout: \"\""
    )
  end

  it 'raises on sleep with a PTY' do
    expect do
      clazz.process(
        'sleep 999',
        timeout: max_process_wait,
        pty: true
      )
    end.to raise_error(
      ProcessHelper::TimeoutError,
      "Timed out after #{@max_process_wait} seconds. Command output prior to timeout: \"\""
    )
  end

  it 'does not raise error if timeout is not exceeded' do
    expect do
      clazz.process(
        'sleep 0.01',
        timeout: max_process_wait
      )
    end.to not_output.to_stdout
      .and(not_output.to_stderr)
  end

  it 'handles a single line of STDIN to STDOUT with ruby output flushing' do
    expect do
      clazz.process(
        "ruby -e 'while(i=$stdin.gets) do puts i; $stdout.flush; end'",
        input: "input1\n",
        puts_output: :never,
        timeout: max_process_wait
      )
    end.to raise_error(
      ProcessHelper::TimeoutError,
      "Timed out after #{@max_process_wait} seconds. Command output prior to timeout: \"" \
          "input1\n\""
    )
  end

  it 'handles multiple lines of STDIN to STDOUT with ruby output flushing' do
    expect do
      clazz.process(
        "ruby -e 'while(i=$stdin.gets) do puts i; $stdout.flush; end'",
        input: "input1\ninput2\n",
        puts_output: :never,
        timeout: max_process_wait
      )
    end.to raise_error(
      ProcessHelper::TimeoutError,
      "Timed out after #{@max_process_wait} seconds. Command output prior to timeout: \"" \
          "input1\ninput2\n\""
    )
  end

  it 'handles cat cmd' do
    expect do
      clazz.process(
        # -u disables output buffering, -n numbers output lines (to distinguish from input)
        'cat -u -n',
        input: "line1\nline2\nline3\n",
        puts_output: :never,
        timeout: max_process_wait
      )
    end.to raise_error(
      ProcessHelper::TimeoutError,
      /Timed out.*1\tline1\n.*2\tline2\n.*3\tline3\n/
    )
  end
end
