require "test_helper"

class ActiveSnapshotTest < ActiveSupport::TestCase

  def test_exposes_main_module
    assert ActiveSnapshot.is_a?(Module)
  end

  def test_exposes_version
    assert ActiveSnapshot::VERSION
  end

  def test_get_deserialized_value_decrypts_ciphertext
    post = Post.create!(a: 1, b: 3)
    comment = post.comments.create!(content: "secret")
    ciphertext = comment.ciphertext_for(:content)

    result = ActiveSnapshot.get_deserialized_value(Comment, key: "content", value: ciphertext)
    assert_equal "secret", result
  end

  def test_get_deserialized_value_falls_back_for_plaintext
    result = ActiveSnapshot.get_deserialized_value(Comment, key: "content", value: "raw plaintext")
    assert_equal "raw plaintext", result
  end

  def test_get_deserialized_value_returns_nil_for_nil
    result = ActiveSnapshot.get_deserialized_value(Comment, key: "content", value: nil)
    assert_nil result
  end

  def test_get_deserialized_value_deserializes_non_encrypted
    result = ActiveSnapshot.get_deserialized_value(Post, key: "title", value: "hello")
    assert_equal "hello", result
  end

  def test_snapshot_lifecycle
    identifier = "snapshot-1"

    parent = Post.create!(a: 1, b: 3)

    original_parent_updated_at = parent.updated_at

    child = parent.comments.create!(content: :foo)
    original_child_updated_at = child.updated_at

    snapshot = nil

    assert_difference ->{ ActiveSnapshot::Snapshot.count }, 1 do
      assert_difference ->{ ActiveSnapshot::SnapshotItem.count }, 2 do
        snapshot = parent.create_snapshot!(identifier: identifier)
      end
    end

    parent.update_columns(updated_at: 1.day.from_now)

    parent.update_columns(updated_at: 1.day.from_now)

    child.destroy!

    parent.comments.create!(content: :foo)
    parent.comments.create!(content: :bar)

    assert_no_difference ->{ ActiveSnapshot::Snapshot.count } do
      assert_no_difference ->{ ActiveSnapshot::SnapshotItem.count } do
        snapshot.restore!
      end
    end

    assert_equal 1, ActiveSnapshot::Snapshot.where(identifier: identifier).count

    parent.reload

    assert_equal 1, parent.children_to_snapshot[:comments][:records].count

    ### Test Data Change
    assert_time_match original_parent_updated_at, parent.updated_at
    assert_time_match original_child_updated_at, parent.children_to_snapshot[:comments][:records].first.updated_at
  end

end
