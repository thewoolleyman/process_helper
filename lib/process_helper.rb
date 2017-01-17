require 'open3'
require 'pty'

# Makes it easier to spawn ruby sub-processes with proper capturing of stdout and stderr streams.
module ProcessHelper
  # Don't forget to keep version in sync with gemspec
  VERSION = '0.0.4-beta'.freeze

  def process(cmd, options = {})
    cmd = cmd.to_s
    fail ProcessHelper::EmptyCommandError, 'command must not be empty' if cmd.empty?
    options = options.dup
    options_processing(options)
    output, process_status =
      if options[:pseudo_terminal]
        process_with_pseudo_terminal(cmd, options)
      else
        process_with_popen(cmd, options)
      end
    handle_exit_status(cmd, options, output, process_status)
    output
  end

  private

  def process_with_popen(cmd, options)
    Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
      begin
        output = get_output(stdin, stdout_and_stderr, options)
      rescue TimeoutError
        # ensure the thread is killed
        wait_thr.kill
        raise
      end
      process_status = wait_thr.value
      return [output, process_status]
    end
  end

  def process_with_pseudo_terminal(cmd, options)
    PTY.spawn(cmd) do |stdout_and_stderr, stdin, pid|
      output = get_output(stdin, stdout_and_stderr, options)
      process_status = PTY.check(pid)
      # TODO: come up with a test that illustrates pid not exiting
      fail "ERROR: pid #{pid} did not exit" unless process_status
      return [output, process_status]
    end
  end

  def warn_if_output_may_be_suppressed_on_error(options)
    return unless options[:puts_output] == :never &&
      options[:include_output_in_exception] == false

    err_msg = 'WARNING: Check your ProcessHelper options - ' \
        ':puts_output is :never, and :include_output_in_exception ' \
        'is false, so all error output will be suppressed if process fails.'
    $stderr.puts(err_msg)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  def get_output(stdin, stdout_and_stderr, options)
    input = options[:input]
    always_puts_output = (options[:puts_output] == :always)
    timeout = options[:timeout]
    output = ''
    begin
      begin
        until input.eof?
          Timeout.timeout(timeout) do
            in_ch = input.read_nonblock(1)
            stdin.write_nonblock(in_ch)
          end
          stdin.flush
        end
        ch = nil
        loop do
          Timeout.timeout(timeout) do
            ch = stdout_and_stderr.read_nonblock(1)
          end
          break unless ch
          printf ch if always_puts_output
          output += ch
          stdout_and_stderr.flush
        end
      rescue EOFError
        return output
      rescue IO::WaitReadable
        result = IO.select([stdout_and_stderr], nil, nil, timeout)
        raise Timeout::Error if result.nil?
        retry
      rescue IO::WaitWritable
        result = IO.select(nil, [stdin], nil, timeout)
        raise Timeout::Error if result.nil?
        retry
      end
    rescue Timeout::Error
      handle_timeout_error(output, options)
    ensure
      stdout_and_stderr.close
      stdin.close
    end
    # TODO: Why do we sometimes get here with no EOFError occurring, but instead
    # via IO::WaitReadable with a nil select result? (via popen, not sure if via tty)
    output
  end

  def handle_timeout_error(output, options)
    msg = "Timed out after #{options.fetch(:timeout)} seconds."
    if options[:include_output_in_exception]
      msg += " Command output prior to timeout: \"#{output}\""
    end
    fail(TimeoutError, msg)
  end

  def handle_exit_status(cmd, options, output, process_status)
    expected_exit_status = options[:expected_exit_status]
    return if expected_exit_status.include?(process_status.exitstatus)

    exception_message = create_exception_message(cmd, process_status, expected_exit_status)
    if options[:include_output_in_exception]
      exception_message += " Command output: \"#{output}\""
    end
    puts_output_only_on_exception(options, output)
    fail ProcessHelper::UnexpectedExitStatusError, exception_message
  end

  def create_exception_message(cmd, exit_status, expected_exit_status)
    if expected_exit_status == [0]
      result_msg = 'failed'
      exit_status_msg = ''
    elsif !expected_exit_status.include?(0)
      result_msg = 'succeeded but was expected to fail'
      exit_status_msg = " (expected #{expected_exit_status})"
    else
      result_msg = 'did not exit with one of the expected exit statuses'
      exit_status_msg = " (expected #{expected_exit_status})"
    end

    "Command #{result_msg}, #{exit_status}#{exit_status_msg}. " \
      "Command: `#{cmd}`."
  end

  def puts_output_only_on_exception(options, output)
    return if options[:puts_output] == :always
    puts output if options[:puts_output] == :error
  end

  def options_processing(options)
    validate_long_vs_short_option_uniqueness(options)
    convert_short_options(options)
    validate_input_option(options[:input]) if options[:input]
    set_option_defaults(options)
    validate_option_values(options)
    convert_scalar_expected_exit_status_to_array(options)
    warn_if_output_may_be_suppressed_on_error(options)
  end

  def validate_input_option(input_option)
    fail(
      ProcessHelper::InvalidOptionsError,
      "#{quote_and_join_pair(%w(input in))} options must be a String or a StringIO"
    ) unless input_option.is_a?(String) || input_option.is_a?(StringIO)
  end

  # rubocop:disable Style/AccessorMethodName
  def set_option_defaults(options)
    options[:puts_output] = :always if options[:puts_output].nil?
    options[:include_output_in_exception] = true if options[:include_output_in_exception].nil?
    options[:pseudo_terminal] = false if options[:pseudo_terminal].nil?
    options[:expected_exit_status] = [0] if options[:expected_exit_status].nil?
    options[:input] = StringIO.new(options[:input].to_s) unless options[:input].is_a?(StringIO)
  end

  def valid_option_pairs
    pairs = [
      %w(expected_exit_status exp_st),
      %w(include_output_in_exception out_ex),
      %w(input in),
      %w(pseudo_terminal pty),
      %w(puts_output out),
      %w(timeout kill),
    ]
    pairs.each do |pair|
      pair.each_with_index do |opt, index|
        pair[index] = opt.to_sym
      end
    end
  end

  def valid_options
    valid_option_pairs.flatten
  end

  def validate_long_vs_short_option_uniqueness(options)
    invalid_options = (options.keys - valid_options)
    fail(
      ProcessHelper::InvalidOptionsError,
      "Invalid option(s) '#{invalid_options.join(', ')}' given.  " \
         "Valid options are: #{valid_options.join(', ')}") unless invalid_options.empty?
    valid_option_pairs.each do |pair|
      long_option_name, short_option_name = pair
      both_long_and_short_option_specified =
        options[long_option_name] && options[short_option_name]
      next unless both_long_and_short_option_specified
      fail(
        ProcessHelper::InvalidOptionsError,
        "Cannot specify both '#{long_option_name}' and '#{short_option_name}'")
    end
  end

  def convert_short_options(options)
    valid_option_pairs.each do |pair|
      long, short = pair
      options[long] = options.delete(short) unless options[short].nil?
    end
  end

  def validate_option_values(options)
    options.each do |option, value|
      valid_option_pairs.each do |pair|
        long_option_name, _ = pair
        next unless option == long_option_name
        validate_integer(pair, value) if option.to_s == 'expected_exit_status'
        validate_boolean(pair, value) if option.to_s == 'include_output_in_exception'
        validate_boolean(pair, value) if option.to_s == 'pseudo_terminal'
        validate_puts_output(pair, value) if option.to_s == 'puts_output'
      end
    end
  end

  def validate_integer(pair, value)
    valid =
      case
        when value.is_a?(Integer)
          true
        when value.is_a?(Array) && value.all? { |v| v.is_a?(Integer) }
          true
        else
          false
      end

    fail(
      ProcessHelper::InvalidOptionsError,
      "#{quote_and_join_pair(pair)} options must be an Integer or an array of Integers"
    ) unless valid
  end

  def validate_boolean(pair, value)
    fail(
      ProcessHelper::InvalidOptionsError,
      "#{quote_and_join_pair(pair)} options must be a boolean"
    ) unless value == true || value == false
  end

  def validate_puts_output(pair, value)
    valid_values = [:always, :error, :never]
    fail(
      ProcessHelper::InvalidOptionsError,
      "#{quote_and_join_pair(pair)} options must be one of the following: " +
        valid_values.map { |v| ":#{v}" }.join(', ')
    ) unless valid_values.include?(value)
  end

  def quote_and_join_pair(pair)
    pair.map { |o| "'#{o}'" }.join(',')
  end

  def convert_scalar_expected_exit_status_to_array(options)
    return if options[:expected_exit_status].is_a?(Array)
    options[:expected_exit_status] =
      [options[:expected_exit_status]]
  end

  # Custom Exception Classes:

  # Error which is raised when a command is empty
  class EmptyCommandError < RuntimeError
  end

  # Error which is raised when options are invalid
  class InvalidOptionsError < RuntimeError
  end

  # Error which is raised when any read or write operation takes longer than timeout (kill) option
  class TimeoutError < RuntimeError
  end

  # Error which is raised when a command returns an unexpected exit status (return code)
  class UnexpectedExitStatusError < RuntimeError
  end

  # Error which is raised when command exists while input remains unprocessed
  class UnprocessedInputError < RuntimeError
  end
end
