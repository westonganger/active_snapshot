require "test_helper"

class SnapshotItemTest < ActiveSupport::TestCase

  def setup
    @snapshot_klass = ActiveSnapshot::Snapshot
    @snapshot_item_klass = ActiveSnapshot::SnapshotItem
  end

  def teardown
  end

  def test_relationships
    instance = @snapshot_item_klass.new

    assert instance.snapshot.nil?
    assert instance.item.nil?

    assert_raises do
      instance.snapshot = instance
    end

    instance.snapshot = ActiveSnapshot::Snapshot.new

    instance.item = instance

    assert_not instance.snapshot.nil?
    assert_not instance.item.nil?
  end

  def test_validations
    instance = @snapshot_item_klass.new
      
    instance.valid?

    [:item_id, :item_type, :snapshot_id].each do |attr|
      assert instance.errors[attr].present? ### presence error
    end

    shared_post = DATA[:shared_post]
    snapshot = shared_post.snapshots.first

    instance = @snapshot_item_klass.new(item: snapshot.item, snapshot: snapshot)

    instance.valid?

    assert instance.errors[:item_id].present? ### uniq error
    assert instance.errors[:item_type].present? ### uniq error

    instance = @snapshot_item_klass.new(item_id: 1, item_type: 'Foobar', snapshot: snapshot)

    assert instance.valid?
  end

  def test_object
    @snapshot = @snapshot_klass.includes(:snapshot_items).first

    @snapshot_item = @snapshot.snapshot_items.first

    assert @snapshot_item.object.is_a?(Hash)

    @snapshot_item.object = {foo: :bar}

    assert 'bar', @snapshot_item.object['foo']
  end

  def test_restore_item!
    @snapshot = @snapshot_klass.includes(:snapshot_items).first

    @snapshot_item = @snapshot.snapshot_items.first

    @snapshot_item.restore_item!
  end

end
