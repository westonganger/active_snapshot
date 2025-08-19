require "test_helper"

class DiffableConcernTest < ActiveSupport::TestCase

  def setup
  end

  def teardown
  end

  
  def test_diff
    post = Post.create!(a: 1, b: 2)
    comment = post.comments.create!(content: "First comment")
    comment_to_destroy = post.comments.create!(content: "Comment to destroy")
    from_snapshot = post.create_snapshot!

    post.update!(a: 3, b: 4)
    comment_to_destroy.destroy!
    new_comment = post.comments.create!(content: "New comment")
    post.comments.reload
    to_snapshot = post.create_snapshot!

    diff = ActiveSnapshot::Snapshot.diff(from_snapshot, to_snapshot)

    assert_equal 3, diff.length

    # Test update
    update_diff = diff.find { |d| d[:action] == :update }
    assert_equal :update, update_diff[:action]
    assert_equal post.id, update_diff[:item_id] 
    assert_equal "Post", update_diff[:item_type]
    assert_equal [1, 3], update_diff[:changes][:a]
    assert_equal [2, 4], update_diff[:changes][:b]

    # Test destroy
    destroy_diff = diff.find { |d| d[:action] == :destroy }
    assert_equal :destroy, destroy_diff[:action]
    assert_equal comment_to_destroy.id, destroy_diff[:item_id]
    assert_equal "Comment", destroy_diff[:item_type]
    assert_equal ["Comment to destroy", nil], destroy_diff[:changes][:content]

    # Test create
    create_diff = diff.find { |d| d[:action] == :create }
    assert_equal :create, create_diff[:action] 
    assert_equal new_comment.id, create_diff[:item_id]
    assert_equal "Comment", create_diff[:item_type]
    assert_equal [nil, "New comment"], create_diff[:changes][:content]

    # Verify unchanged comment not in diff
    assert_nil(diff.find { |d| d[:item_id] == comment.id && d[:item_type] == "Comment" })
  end

  def test_diff_between_snapshot_and_instance
    post = Post.create!(a: 1, b: 2)
    comment = post.comments.create!(content: "First comment")
    comment_to_destroy = post.comments.create!(content: "Comment to destroy")
    from_snapshot = post.create_snapshot!

    post.update!(a: 3, b: 4)
    comment_to_destroy.destroy!
    new_comment = post.comments.create!(content: "New comment")
    post.comments.reload

    diff = ActiveSnapshot::Snapshot.diff(from_snapshot, post)

    assert_equal 3, diff.length

    update_diff = diff.find { |d| d[:action] == :update }
    assert_equal :update, update_diff[:action]
    assert_equal post.id, update_diff[:item_id] 
    assert_equal "Post", update_diff[:item_type]
    assert_equal [1, 3], update_diff[:changes][:a]
    assert_equal [2, 4], update_diff[:changes][:b]

    destroy_diff = diff.find { |d| d[:action] == :destroy }
    assert_equal :destroy, destroy_diff[:action]
    assert_equal comment_to_destroy.id, destroy_diff[:item_id]
    assert_equal "Comment", destroy_diff[:item_type]
    assert_equal ["Comment to destroy", nil], destroy_diff[:changes][:content]

    create_diff = diff.find { |d| d[:action] == :create }
    assert_equal :create, create_diff[:action] 
    assert_equal new_comment.id, create_diff[:item_id]
    assert_equal "Comment", create_diff[:item_type]
    assert_equal [nil, "New comment"], create_diff[:changes][:content]
  end

  def test_argument_error_when_from_is_not_a_snapshot
    post = Post.create!
    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(post, post)
    end
  end

  def test_argument_error_when_from_and_to_are_not_the_same_item
    post1 = Post.create!
    snapshot1 = post1.create_snapshot!
    post2 = Post.create!
    snapshot2 = post2.create_snapshot!

    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(snapshot1, snapshot2)
    end
  end

  def test_argument_error_when_from_and_to_are_not_the_same_item_and_one_is_an_instance
    post1 = Post.create!
    snapshot1 = post1.create_snapshot!
    post2 = Post.create!

    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(snapshot1, post2)
    end
  end

  def test_argument_error_when_from_is_not_newer_than_to
    post = Post.create!
    snapshot1 = post.create_snapshot!
    post.update!(a: 1)

    snapshot2 = post.create_snapshot!

    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(snapshot2, snapshot1)
    end
  end
end
