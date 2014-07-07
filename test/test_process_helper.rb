require 'minitest_helper'

class TestProcessHelper < MiniTest::Unit::TestCase
  def test_that_it_has_a_version_number
    refute_nil ::ProcessHelper::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
