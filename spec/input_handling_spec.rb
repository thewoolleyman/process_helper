require_relative 'spec_helper'

RSpec.describe 'input handling' do
  attr_reader :clazz, :max_process_wait

  before do
    @clazz = Clazz.new
    @max_process_wait = ENV['MAX_PROCESS_WAIT'] ? ENV['MAX_PROCESS_WAIT'].to_f : 0.5
  end

  describe 'with non-exiting blocking cmd requiring timeout' do
    it 'handles a single line of STDIN to STDOUT with ruby output flushing' do
      expect do
        clazz.process(
          "ruby -e 'while(i=$stdin.gets) do puts i; $stdout.flush; end'",
          input_lines: ['input1'],
          timeout: max_process_wait
        )
      end.to output(/input1\n/).to_stdout
          .and(not_output.to_stderr)
    end

    it 'handles multiple lines of STDIN to STDOUT with ruby output flushing' do
      expect do
        clazz.process(
          "ruby -e 'while(i=$stdin.gets) do puts i; $stdout.flush; end'",
          input_lines: %w(input1 input2),
          timeout: max_process_wait
        )
      end.to output(/input1\ninput2\n/).to_stdout
          .and(not_output.to_stderr)
    end

    it 'handles cat cmd' do
      expect do
        clazz.process(
          # -u disables output buffering, -n numbers output lines (to distinguish from input)
          'cat -u -n',
          # TODO: how to send Ctrl-D to exit without timeout being required?
          input_lines: ['line1', 'line2', 'line3', "\C-d"],
          timeout: max_process_wait
        )
      end.to output(/.*1\tline1\n.*2\tline2\n.*3\tline3\n.*4\t\u0004\n/).to_stdout
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
          input_lines: %w(line1 line2 line3 exit),
          timeout: max_process_wait
        )
      end.to output(/out:line1\nerr:line1\nout:line2\nerr:line2\nout:line3\nerr:line3\n/).to_stdout
          .and(not_output.to_stderr)
    end
  end

  describe 'with exiting cmd' do
    it 'handles stdout and stderr triggered via stdin' do
      expect do
        clazz.process(
          'irb -f --prompt=default',
          input_lines: [
            '$stdout.puts "hi"',
            '$stdout.flush',
            '$stderr.puts "aaa\nbbb\nccc"',
            '$stderr.flush',
            '$stdout.puts "bye"',
            '$stdout.flush',
            'exit'
          ]
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
          input_lines: ['hi']
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
          input_lines: ['hi']
        )
      end.to output(/hi\n/m).to_stdout
          .and(not_output.to_stderr)
    end

    it 'fails if unprocessed input remains when command exits' do
      expect do
        clazz.process(
          "ruby -e 'i=$stdin.gets; $stdout.puts i; exit'",
          input_lines: %w(hi unprocessed)
        )
      end.to raise_error(
          ProcessHelper::UnprocessedInputError,
          /Output stream closed with 1 input lines left unprocessed/)
          .and(output(/hi\n/).to_stdout)
    end
  end
end
