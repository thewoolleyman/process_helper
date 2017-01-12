require_relative 'spec_helper'

RSpec.describe 'pty handling' do
  attr_reader :clazz, :max_process_wait

  before do
    skip('pty specs do not work on travis or circle ci (try docker with -t option)') if ENV['CI']
    @clazz = Clazz.new
  end

  it 'handles cat cmd' do
    expect do
      clazz.process(
        # -u disables output buffering, -n numbers output lines (to distinguish from input)
        'cat -u -n',
        input: "line1\nline2\nline3\n\C-d\n",
        pty: true
      )
    end.to output(/1\tline1\r\n.*2\tline2\r\n.*3\tline3\r\n/).to_stdout
      .and(not_output.to_stderr)
  end

  it 'respects "stty -onlcr"' do
    # NOTE: the `stty -a` default on OSX and Linux terminals seems to be 'onlcr', so all PTY slave
    #       terminals which inherit that will transform "\n" into "\r\n".  This test shows how to
    #       avoid that behavior by prepending 'stty -onlcr && ' to the command
    expect do
      clazz.process(
        'stty -onlcr && printf "stdout\n" > /dev/stdout && printf "stderr\n" > /dev/stderr',
        puts_output: :always,
        pty: true
      )
    end.to output("stdout\nstderr\n").to_stdout
      .and(not_output.to_stderr)
  end

  it 'does not require a newline or flush via getch' do
    skip('TODO: this test just hangs, including in a debugger')
    expect do
      clazz.process(
        %q(ruby -e 'require "io/console"; i=$stdin.getch; puts "4" + i;'),
        input: '2',
        pty: true
      )
    end.to output(/42/).to_stdout
      .and(not_output.to_stderr)
  end
end
