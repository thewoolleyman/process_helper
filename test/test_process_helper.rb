require_relative 'minitest_helper'

class Clazz
  include ProcessHelper
end

class TestProcessHelper < MiniTest::Unit::TestCase
  def setup
    @clazz = Clazz.new
  end

  def test_has_a_version_number
    refute_nil ::ProcessHelper::VERSION
  end

  def test_captures_stdout_only
    output = @clazz.process('echo stdout > /dev/stdout && echo stderr > /dev/null')
    assert_equal "stdout\n", output
  end

  def test_captures_stderr_only
    output = @clazz.process('echo stdout > /dev/null && echo stderr > /dev/stderr')
    assert_equal "stderr\n", output
  end

  def test_captures_stdout_and_stderr
    output = @clazz.process('echo stdout > /dev/stdout && echo stderr > /dev/stderr')
    assert_equal "stdout\nstderr\n", output
  end
end
