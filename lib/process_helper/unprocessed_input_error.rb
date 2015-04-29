# Error which is raised when command exists while input lines remain unprocessed
module ProcessHelper
  class UnprocessedInputError < RuntimeError
  end
end
