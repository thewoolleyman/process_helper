require_relative 'process_helper/version'
require_relative 'process_helper/empty_command_error'
require_relative 'process_helper/invalid_options_error'
require_relative 'process_helper/unexpected_exit_status_error'
require 'open3'

# Makes it easier to spawn ruby sub-processes with proper capturing of stdout and stderr streams.
module ProcessHelper
  def process(cmd, options = {})
    cmd = cmd.to_s
    fail ProcessHelper::EmptyCommandError, 'command must not be empty' if cmd.empty?
    options = options.dup
    options_processing(options)
    Open3.popen2e(cmd) do |_, stdout_and_stderr, wait_thr|
      output = ''
      while (line = stdout_and_stderr.gets)
        output += line
      end
      puts output if options[:puts_output] == :always

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

  def handle_exit_status(cmd, options, output, wait_thr)
    expected_exit_status = options[:expected_exit_status] || 0
    exit_status = wait_thr.value
    return if exit_status.exitstatus == expected_exit_status

    if expected_exit_status == 0
      result_msg = 'failed'
      exit_status_msg = ''
    else
      result_msg = 'succeeded but was expected to fail'
      exit_status_msg = " (expected #{expected_exit_status})"
    end

    exception_message = "Command #{result_msg}, #{exit_status}#{exit_status_msg}. " \
    "Command: `#{cmd}`."
    if options[:include_output_in_exception]
      exception_message += " Command Output: \"#{output}\""
    end
    puts_output_only_on_exception(options, output)
    fail UnexpectedExitStatusError, exception_message
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
    warn_if_output_may_be_suppressed_on_error(options)
  end

  # rubocop:disable Style/AccessorMethodName
  def set_option_defaults(options)
    options[:puts_output] = :always if options[:puts_output].nil?
    options[:include_output_in_exception] = true if options[:include_output_in_exception].nil?
    options[:expected_exit_status] = 0 if options[:expected_exit_status].nil?
  end

  def valid_option_pairs
    pairs = [
      %w(expected_exit_status exp_st),
      %w(include_output_in_exception out_ex),
      %w(puts_output out),
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
    fail(
      ProcessHelper::InvalidOptionsError,
      "#{quote_and_join_pair(pair)} options must be an Integer"
    ) unless value.is_a?(Integer)
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
end
