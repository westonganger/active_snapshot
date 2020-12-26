require "test_helper"

class SnapshotTest < ActiveSupport::TestCase

  def setup
    @snapshot = Snapshot.first
  end

  def teardown
  end

  def test_relationships
    # TODO
  end

  def test_validations
    # TODO
  end

  def test_metadata
    assert @snapshot.metadata.is_a?(HashWithIndifferentAccess)

    @snapshot.metadata = {foo: :bar}

    assert_equal 'bar', @snapshot.metadata['foo']
  end

  def test_build_snapshot_item
    snapshot_item = @snapshot.build_snapshot_item(Post.first)

    assert snapshot_item.is_a?(ActiveSnapshot::SnapshotItem)

    assert snapshot_item.new_record?

    assert_equal @snapshot.id, snapshot_item.parent_version_id

    @snapshot.build_snapshot_item(Post.first, child_type_name: :foobar)
  end

  def test_restore
    @snapshot.restore!
  end

  def test_fetch_reified_items
    reified_items = @snapshot.fetch_reified_items

    assert reified_items.is_a?(Array)

    assert reified_items.first.readonly?

    children_hash = reified_items.last

    assert children_hash.is_a?(HashWithIndifferentAccess)

    assert children_hash.all?{|k,v| v.all?{|x| x.readonly?} }
  end

  def test_children_definition_error
    exception = ActiveSnapshot::Snapshot::ChildrenDefinitionError.new("Foobar.")

    assert_equal exception.message, "Invalid `has_snapshot_children` definition. Foobar. For example: \n\n#{exception.class::EXAMPLE}"
  end

  def test_kitchen_sink
    # TODO
  end

end
