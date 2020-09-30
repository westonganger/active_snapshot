require "test_helper"

class ActiveSnapshotTest < Minitest::Test
  def test_version_number
    assert_not_nil ActiveSnapshot::VERSION
  end

  def test_it_does_something_useful
    assert true
  end
end
