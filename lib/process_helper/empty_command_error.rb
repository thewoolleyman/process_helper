# Error which is raised when a command returns an unexpected exit status (return code)
module ProcessHelper
  class EmptyCommandError < RuntimeError
  end
end