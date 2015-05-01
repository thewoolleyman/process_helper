require 'open3'

# Makes it easier to spawn ruby sub-processes with proper capturing of stdout and stderr streams.
module ProcessHelper
  PROCESS_HELPER_VERSION = '0.0.3'

  def process(cmd, options = {})
    cmd = cmd.to_s
    fail ProcessHelper::EmptyCommandError, 'command must not be empty' if cmd.empty?
    options = options.dup
    options_processing(options)
    Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
      always_puts_output = (options[:puts_output] == :always)
      output = get_output(
        stdin,
        stdout_and_stderr,
        options[:input_lines],
        always_puts_output,
        options[:timeout]
      )
      stdin.close
      handle_exit_status(cmd, options, output, wait_thr)
      output
    end
  end

  private

  def warn_if_output_may_be_suppressed_on_error(options)
    return unless options[:puts_output] == :never

    if options[:include_output_in_exception] == false
      err_msg = 'WARNING: Check your ProcessHelper options - ' \
        ':puts_output is :never, and :include_output_in_exception ' \
        'is false, so all error output will be suppressed if process fails.'
    else
      err_msg = 'WARNING: Check your ProcessHelper options - ' \
        ':puts_output is :never, ' \
        'so all error output will be suppressed unless process ' \
        "fails with an exit code other than #{options[:expected_exit_status]} " \
        '(in which case exception will include output ' \
        'because :include_output_in_exception is true)'
    end
    $stderr.puts(err_msg)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  def get_output(stdin, stdout_and_stderr, original_input_lines, always_puts_output, timeout)
    input_lines = original_input_lines.dup
    input_lines_processed = 0
    current_input_line_processed = false
    output = ''
    begin
      while (output_line = readline_nonblock(stdout_and_stderr))
        current_input_line_processed = true
        puts output_line if always_puts_output
        output += output_line
        output_line = nil
      end
    rescue EOFError
      input_lines_processed -= 1 if !original_input_lines.empty? && !current_input_line_processed
      fail_unless_all_input_lines_processed(original_input_lines, input_lines_processed)
    rescue IO::WaitReadable
      if input_lines.empty?
        result = IO.select([stdout_and_stderr], nil, nil, timeout)
        retry unless result.nil?
      else
        current_input_line_processed = false
        puts_input_line_to_stdin(stdin, input_lines)
        input_lines_processed += 1
        result = IO.select([stdout_and_stderr], nil, nil, timeout)
        retry
      end
    end
    output
  end

  def readline_nonblock(io)
    buffer = ''
    while (ch = io.read_nonblock(1))
      buffer << ch
      if ch == "\n"
        result = buffer
        return result
      end
    end
  end

  def fail_unless_all_input_lines_processed(original_input_lines, input_lines_processed)
    unprocessed_input_lines = original_input_lines.length - input_lines_processed
    msg = "Output stream closed with #{unprocessed_input_lines} " \
    'input lines left unprocessed:' \
    "#{original_input_lines[-(unprocessed_input_lines)..-1]}"
    fail(
      ProcessHelper::UnprocessedInputError,
      msg
    ) unless unprocessed_input_lines == 0
  end

  def puts_input_line_to_stdin(stdin, input_lines)
    return if input_lines.empty?
    input_line = input_lines.shift
    stdin.puts(input_line)
  end

  def handle_exit_status(cmd, options, output, wait_thr)
    expected_exit_status = options[:expected_exit_status]
    exit_status = wait_thr.value
    return if expected_exit_status.include?(exit_status.exitstatus)

    exception_message = create_exception_message(cmd, exit_status, expected_exit_status)
    if options[:include_output_in_exception]
      exception_message += " Command Output: \"#{output}\""
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
    set_option_defaults(options)
    validate_option_values(options)
    convert_scalar_expected_exit_status_to_array(options)
    warn_if_output_may_be_suppressed_on_error(options)
  end

  # rubocop:disable Style/AccessorMethodName
  def set_option_defaults(options)
    options[:puts_output] = :always if options[:puts_output].nil?
    options[:include_output_in_exception] = true if options[:include_output_in_exception].nil?
    options[:expected_exit_status] = [0] if options[:expected_exit_status].nil?
    options[:input_lines] = [] if options[:input_lines].nil?
  end

  def valid_option_pairs
    pairs = [
      %w(expected_exit_status exp_st),
      %w(include_output_in_exception out_ex),
      %w(input_lines in),
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

  # Error which is raised when a command returns an unexpected exit status (return code)
  class UnexpectedExitStatusError < RuntimeError
  end

  # Error which is raised when command exists while input lines remain unprocessed
  class UnprocessedInputError < RuntimeError
  end
end
