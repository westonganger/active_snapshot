require "test_helper"

class SnapshotsConcernTest < ActiveSupport::TestCase

  def setup
  end

  def teardown
  end

  def test_relationships
    # TODO
  end

  def test_create_snapshot!
    @post = Post.first

    snapshot = @post.create_snapshot!("foobar 1", user: @user, metadata: {foo: :bar})
    assert_not snapshot.new_record?

    snapshot = @post.create_snapshot!("foobar 2", user: @user)
    assert_not snapshot.new_record?

    snapshot = @post.create_snapshot!("foobar 3")
    assert_not snapshot.new_record?

    assert_raise do
      @post.create_snapshot!("foobar 3")
    end
  end

  def test_has_snapshot_children
    # TODO
  end

  def test_kitchen_sink
    # TODO
  end

end
