require "test_helper"

class ActiveSnapshotTest < Minitest::Test

  def test_exposes_main_module
    assert ActiveSnapshot.is_a?(Module)
  end

  def test_exposes_version
    assert ActiveSnapshot::VERSION
  end

  def test_snapshot_lifecycle
    identifier = "snapshot-1"

    skip("TODO")

    klass = ParentModel

    puts klass.name

    parent = klass.first

    original_parent_updated_at = parent.updated_at

    child_model = parent.child_models.create!(content: :foo)
    original_child_updated_at = child_model.updated_at

    children_size = parent.children_to_snapshot.size

    assert_difference ->{ Snapshot.count }, 1 do
      assert_difference ->{ SnapshotItem.count }, (children_size+1) do
        @snapshot = parent.create_snapshot!(identifier)
      end
    end

    assert_equal (children_size+1), @snapshot.snapshot_items.size

    parent.touch

    original_child.touch

    original_child.destroy!

    parent.child_models.create!(content: :foo)
    parent.child_models.create!(content: :bar)

    increase = 1

    parent.reload
    assert_equal (children_size+increase), parent.children_to_snapshot.size

    assert_difference ->{ Snapshot.count }, -1 do
      assert_difference ->{ SnapshotItem.count }, (-@snapshot.snapshot_items.size) do
        @snapshot.restore!(@snapshot)
      end
    end

    assert_equal 0, Snapshot.where(identifier: identifier).count

    parent.reload
    assert_equal children_size, parent.children_to_snapshot.size

    ### Test Data Changed
    assert_equal original_parent_updated_at, parent.updated_at
    assert_equal original_child_updated_at, parent.child_models.first.updated_at

  end
end
