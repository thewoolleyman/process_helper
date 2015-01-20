require "process_helper/version"
require "open3"

module ProcessHelper
  def process(cmd)
    cmd = cmd.to_s
    fail 'command must not be empty' if cmd.empty?
    Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
      output = ''
      while line = stdout_and_stderr.gets
        puts line
        output += line
      end
      output
    end
  end
end
