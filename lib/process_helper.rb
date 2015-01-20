require "process_helper/version"
require "open3"

module ProcessHelper
  def process(cmd, options = {})
    cmd = cmd.to_s
    fail 'command must not be empty' if cmd.empty?
    options = options.dup
    Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
      output = ''
      while line = stdout_and_stderr.gets
        output += line
        puts output unless options[:puts_output] == false
      end
      output
    end
  end
end
