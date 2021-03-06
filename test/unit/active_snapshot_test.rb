require "test_helper"

class ActiveSnapshotTest < ActiveSupport::TestCase

  def test_exposes_main_module
    assert ActiveSnapshot.is_a?(Module)
  end

  def test_exposes_version
    assert ActiveSnapshot::VERSION
  end

  def test_snapshot_lifecycle
    identifier = "snapshot-1"

    klass = Post

    parent = klass.first

    original_parent_updated_at = parent.updated_at

    child = parent.comments.create!(content: :foo)
    original_child_updated_at = child.updated_at

    orig_comments_size = parent.children_to_snapshot[:comments][:records].count

    assert_difference ->{ ActiveSnapshot::Snapshot.count }, 1 do
      assert_difference ->{ ActiveSnapshot::SnapshotItem.count }, (orig_comments_size+1) do
        @snapshot = parent.create_snapshot!(identifier)
      end
    end

    assert_equal (orig_comments_size+1), @snapshot.snapshot_items.size

    parent.update_columns(updated_at: 1.day.from_now)

    parent.update_columns(updated_at: 1.day.from_now)

    child.destroy!

    parent.comments.create!(content: :foo)
    parent.comments.create!(content: :bar)

    assert_no_difference ->{ ActiveSnapshot::Snapshot.count } do
      assert_no_difference ->{ ActiveSnapshot::SnapshotItem.count } do
        @snapshot.restore!
      end
    end

    assert_equal 1, ActiveSnapshot::Snapshot.where(identifier: identifier).count

    parent.reload

    assert_equal orig_comments_size, parent.children_to_snapshot[:comments][:records].count

    ### Test Data Chang
    assert_time_match original_parent_updated_at, parent.updated_at
    assert_time_match original_child_updated_at, parent.children_to_snapshot[:comments][:records].first.updated_at
  end
end
