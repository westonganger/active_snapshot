require "test_helper"

class SnapshotItemTest < ActiveSupport::TestCase

  def setup
  end

  def teardown
  end

  def test_relationships
    # TODO
  end

  def test_validations
    # TODO
  end

  def test_object
    @snapshot = ActiveSnapshot::Snapshot.includes(:snapshot_items).first

    @snapshot_item = @snapshot.snapshot_items.first

    assert @snapshot_item.object.is_a?(HashWithIndifferentAccess)

    @snapshot_item.object = {foo: :bar}

    assert 'bar', @snapshot_item.object['foo']
  end

  def test_restore_item!
    @snapshot = ActiveSnapshot::Snapshot.includes(:snapshot_items).first

    @snapshot_item = @snapshot.snapshot_items.first

    @snapshot_item.restore_item!
  end

  def test_kitchen_sink
    # TODO
  end

end
