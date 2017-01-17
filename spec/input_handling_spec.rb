require_relative 'spec_helper'

RSpec.describe 'input handling' do
  attr_reader :clazz, :max_process_wait

  before do
    @clazz = Clazz.new
  end

  it 'handles a single line of STDIN to STDOUT with ruby output flushing' do
    expect do
      clazz.process(
        "ruby -e 'i=$stdin.gets; puts i; $stdout.flush'",
        input: "input1\n"
      )
    end.to output(/input1\n/).to_stdout
      .and(not_output.to_stderr)
  end

  it 'handles multiple lines of STDIN to STDOUT with ruby output flushing' do
    expect do
      clazz.process(
        "ruby -e 'while(i=$stdin.gets) do puts i; $stdout.flush; ; if i =~ /2/; break; end; end'",
        input: "input1\ninput2\n"
      )
    end.to output(/input1\ninput2\n/).to_stdout
      .and(not_output.to_stderr)
  end

  it 'handles interleaved stdout and stderr based on stdin input' do
    expect do
      cmd =
        'while ' \
          '  line = $stdin.readline; ' \
          '  $stdout.puts("out:#{line}"); ' \
          '  $stdout.flush; ' \
          '  $stderr.puts("err:#{line}"); ' \
          '  $stderr.flush; ' \
          '  exit 0 if line =~ /exit/; ' \
          'end'
      clazz.process(
        %(ruby -e '#{cmd}'),
        input: "line1\nline2\nline3\nexit\n"
      )
    end.to output(/out:line1\nerr:line1\nout:line2\nerr:line2\nout:line3\nerr:line3\n/).to_stdout
      .and(not_output.to_stderr)
  end

  it 'handles stdout and stderr triggered via stdin' do
    expect do
      clazz.process(
        'irb -f --prompt=default',
        input: [
          '$stdout.puts "hi"',
          '$stdout.flush',
          '$stderr.puts "aaa\nbbb\nccc"',
          '$stderr.flush',
          '$stdout.puts "bye"',
          '$stdout.flush',
          "exit\n"
        ].join("\n")
      )
    end.to output(/\nhi\n.*\naaa\nbbb\nccc.*\nbye\n/m).to_stdout
      .and(not_output.to_stderr)
  end

  it 'handles unexpected exit status' do
    expect do
      clazz.process(
        "ruby -e 'i=$stdin.gets; $stdout.puts i; $stdout.flush; " \
          "$stderr.puts i; $stderr.flush; exit 1'",
        puts_output: :error,
        input: "hi\n"
      )
    end.to raise_error(
      ProcessHelper::UnexpectedExitStatusError,
      /Command failed/)
      .and(output(/hi\nhi\n/).to_stdout)
  end

  it 'pipes input before processing output' do
    expect do
      clazz.process(
        "ruby -e 'i=$stdin.gets; $stdout.puts i; $stdout.flush; exit'",
        input: "hi\n"
      )
    end.to output(/hi\n/m).to_stdout
      .and(not_output.to_stderr)
  end

  it 'allows a StringIO as input' do
    expect do
      clazz.process(
        "ruby -e 'i=$stdin.gets; $stdout.puts i; $stdout.flush; exit'",
        input: StringIO.new("hi\n")
      )
    end.to output(/hi\n/m).to_stdout
      .and(not_output.to_stderr)
  end
end
