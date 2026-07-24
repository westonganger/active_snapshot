require "test_helper"

class SnapshotItemTest < ActiveSupport::TestCase

  def setup
  end

  def teardown
  end

  def test_validations
    snapshot_item = ActiveSnapshot::SnapshotItem.new

    assert_not snapshot_item.valid?

    [:item_id, :item_type, :snapshot_id, :object].each do |attr|
      assert_equal ["can't be blank"], snapshot_item.errors[attr] ### presence error
    end

    post = Post.create!(a: 1, b: 3)
    snapshot = post.create_snapshot!(identifier: "v1")

    snapshot_item = ActiveSnapshot::SnapshotItem.new(item: snapshot.item, snapshot: snapshot)

    assert_not snapshot_item.valid?

    assert_equal ["has already been taken"], snapshot_item.errors[:item_id] ### uniq error
  end

  def test_object
    post = Post.create!(a: 1, b: 3)
    snapshot = post.create_snapshot!(identifier: "v1")
    snapshot_item = snapshot.snapshot_items.first!

    assert snapshot_item.object.is_a?(Hash)

    snapshot_item.object = {foo: :bar}

    assert 'bar', snapshot_item.object['foo']
  end

  def test_restore_item
    post = Post.create!(a: 1, b: 3)
    snapshot = post.create_snapshot!(identifier: "v1")
    snapshot_item = snapshot.snapshot_items.first!

    assert_nothing_raised do
      snapshot_item.restore_item!
    end
  end

  def test_restore_item_handles_dropped_columns
    post = Post.create!(a: 1, b: 3)
    snapshot = post.create_snapshot!(identifier: "v1")
    snapshot_item = snapshot.snapshot_items.first!

    attrs = snapshot_item.object
    attrs["foo"] = "bar"

    snapshot_item.update!(object: attrs)

    assert_nothing_raised do
      snapshot_item.restore_item!
    end
  end

end
