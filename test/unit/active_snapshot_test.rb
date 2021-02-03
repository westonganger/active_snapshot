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

    children_size = klass.has_snapshot_children.size

    assert_difference ->{ ActiveSnapshot::Snapshot.count }, 1 do
      assert_difference ->{ ActiveSnapshot::SnapshotItem.count }, (children_size+1) do
        @snapshot = parent.create_snapshot!(identifier)
      end
    end

    assert_equal (children_size+1), @snapshot.snapshot_items.size

    parent.touch

    child.touch

    child.destroy!

    parent.comments.create!(content: :foo)
    parent.comments.create!(content: :bar)

    parent.reload

    assert_difference ->{ ActiveSnapshot::Snapshot.count }, -1 do
      assert_difference ->{ ActiveSnapshot::SnapshotItem.count }, (-@snapshot.snapshot_items.size) do
        @snapshot.restore!
      end
    end

    assert_equal 0, ActiveSnapshot::Snapshot.where(identifier: identifier).count

    parent.reload
    assert_equal children_size, parent.children_to_snapshot.size

    ### Test Data Changed
    assert_equal original_parent_updated_at, parent.updated_at
    assert_equal original_child_updated_at, parent.child_models.first.updated_at

  end
end
