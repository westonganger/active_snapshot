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

    diff = ActiveSnapshot::Snapshot.diff(from: from_snapshot, to: to_snapshot)

    assert_equal 3, diff.length

    # Test update
    update_diff = diff.find { |d| d[:action] == :update }
    assert_equal :update, update_diff[:action]
    assert_equal post.id, update_diff[:item_id] 
    assert_equal "Post", update_diff[:item_type]
    assert_equal 1, update_diff[:changes][:a][:from]
    assert_equal 3, update_diff[:changes][:a][:to]
    assert_equal 2, update_diff[:changes][:b][:from] 
    assert_equal 4, update_diff[:changes][:b][:to]

    # Test destroy
    destroy_diff = diff.find { |d| d[:action] == :destroy }
    assert_equal :destroy, destroy_diff[:action]
    assert_equal comment_to_destroy.id, destroy_diff[:item_id]
    assert_equal "Comment", destroy_diff[:item_type]
    assert_equal "Comment to destroy", destroy_diff[:changes][:content][:from]
    assert_nil destroy_diff[:changes][:content][:to]

    # Test create
    create_diff = diff.find { |d| d[:action] == :create }
    assert_equal :create, create_diff[:action] 
    assert_equal new_comment.id, create_diff[:item_id]
    assert_equal "Comment", create_diff[:item_type]
    assert_nil create_diff[:changes][:content][:from]
    assert_equal "New comment", create_diff[:changes][:content][:to]

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

    diff = ActiveSnapshot::Snapshot.diff(from: from_snapshot, to: post)

    assert_equal 3, diff.length

    update_diff = diff.find { |d| d[:action] == :update }
    assert_equal :update, update_diff[:action]
    assert_equal post.id, update_diff[:item_id] 
    assert_equal "Post", update_diff[:item_type]
    assert_equal 1, update_diff[:changes][:a][:from]
    assert_equal 3, update_diff[:changes][:a][:to]
    assert_equal 2, update_diff[:changes][:b][:from] 
    assert_equal 4, update_diff[:changes][:b][:to]

    destroy_diff = diff.find { |d| d[:action] == :destroy }
    assert_equal :destroy, destroy_diff[:action]
    assert_equal comment_to_destroy.id, destroy_diff[:item_id]
    assert_equal "Comment", destroy_diff[:item_type]
    assert_equal "Comment to destroy", destroy_diff[:changes][:content][:from]
    assert_nil destroy_diff[:changes][:content][:to]

    create_diff = diff.find { |d| d[:action] == :create }
    assert_equal :create, create_diff[:action] 
    assert_equal new_comment.id, create_diff[:item_id]
    assert_equal "Comment", create_diff[:item_type]
    assert_nil create_diff[:changes][:content][:from]
    assert_equal "New comment", create_diff[:changes][:content][:to]
  end

  def test_argument_error_when_from_and_to_are_not_snapshots
    post = Post.create!
    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(from: post, to: post)
    end
  end

  def test_argument_error_when_from_and_to_are_not_the_same_item
    post1 = Post.create!
    snapshot1 = post1.create_snapshot!
    post2 = Post.create!
    snapshot2 = post2.create_snapshot!

    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(from: snapshot1, to: snapshot2)
    end
  end

  def test_argument_error_when_from_and_to_are_not_the_same_item_and_one_is_an_instance
    post1 = Post.create!
    snapshot1 = post1.create_snapshot!
    post2 = Post.create!

    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(from: snapshot1, to: post2)
    end
  end
end
