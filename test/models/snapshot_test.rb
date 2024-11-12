require "test_helper"

class SnapshotTest < ActiveSupport::TestCase

  def setup
    @snapshot_klass = ActiveSnapshot::Snapshot
  end

  def teardown
  end

  def test_relationships
    shared_post = DATA[:shared_post]

    instance = @snapshot_klass.new

    assert instance.user.nil?
    assert instance.item.nil?
    assert instance.snapshot_items.empty?

    instance.user = instance
    instance.item = instance

    assert_raises do
      instance.snapshot_items << instance
    end

    instance.snapshot_items << ActiveSnapshot::SnapshotItem.new

    assert_not instance.user.nil?
    assert_not instance.item.nil?
    assert_not instance.snapshot_items.empty?

    instance = @snapshot_klass.new(item: shared_post, user: shared_post)

    assert instance.item.id, shared_post.id
    assert instance.user.id, shared_post.id
  end

  def test_validations
    shared_post = DATA[:shared_post]
    snapshot = shared_post.snapshots.first

    instance = @snapshot_klass.new

    instance.valid?

    [:item_id, :item_type].each do |attr|
      assert instance.errors[attr].present? ### presence error
    end

    instance = @snapshot_klass.new(item: snapshot.item, identifier: snapshot.identifier)

    instance.valid?

    assert instance.errors[:identifier].present? ### uniq error

    instance = @snapshot_klass.new(item: snapshot.item, identifier: 'random')

    assert instance.valid?
  end

  def test_metadata
    @snapshot = @snapshot_klass.first

    assert @snapshot.metadata.is_a?(Hash)

    @snapshot.metadata = {foo: :bar}

    if ActiveSnapshot.config.storage_method_yaml?
      assert_equal :bar, @snapshot.metadata.fetch(:foo)
    else
      assert_equal "bar", @snapshot.metadata.fetch("foo")
    end
  end

  def test_build_snapshot_item
    @snapshot = @snapshot_klass.first

    snapshot_item = @snapshot.build_snapshot_item(Post.first)

    assert snapshot_item.is_a?(ActiveSnapshot::SnapshotItem)

    assert snapshot_item.new_record?

    assert_equal @snapshot.id, snapshot_item.snapshot_id

    @snapshot.build_snapshot_item(Post.first, child_group_name: :foobar)
  end

  def test_snapshot_item_stores_enum_column_database_value
    assert Post.defined_enums.has_key?("status")

    post = Post.first

    enum_mapping = post.class.defined_enums.fetch("status")

    post.status = "published"

    snapshot = post.create_snapshot!(identifier: "enum-test")

    snapshot_item = snapshot.snapshot_items.find_by(item_type: "Post")

    stored_value = snapshot_item.object["status"]

    assert_equal 1, stored_value
    assert_equal "published", enum_mapping.invert.fetch(stored_value)
  end

  def test_snapshot_item_handles_nil_enum_column_value
    assert Post.defined_enums.has_key?("status")

    post = Post.first

    enum_mapping = post.class.defined_enums.fetch("status")

    post.status = nil

    snapshot = post.create_snapshot!(identifier: "enum-test")

    snapshot_item = snapshot.snapshot_items.find_by(item_type: "Post")

    stored_value = snapshot_item.object["status"]

    assert_equal nil, stored_value
  end

  def test_snapshot_item_handles_enum_values_from_select_statement
    assert Post.defined_enums.has_key?("status")

    assert_equal "draft", Post.first.status

    post = Post.select(:id).first

    snapshot = post.create_snapshot!(identifier: "enum-test")

    snapshot_item = snapshot.snapshot_items.find_by(item_type: "Post")

    stored_value = snapshot_item.object["status"]

    assert_equal nil, stored_value
  end

  def test_restore
    @snapshot = @snapshot_klass.first

    @snapshot.restore!
  end

  def test_fetch_reified_items_with_readonly
    @snapshot = @snapshot_klass.first

    reified_items = @snapshot.fetch_reified_items

    assert reified_items.is_a?(Array)

    assert reified_items.first.readonly?

    children_hash = reified_items.last

    assert children_hash.is_a?(Hash)

    assert children_hash.values.all?(&:readonly?)
  end

  def test_fetch_reified_items_without_readonly
    @snapshot = @snapshot_klass.first

    reified_items = @snapshot.fetch_reified_items(readonly: false)

    assert reified_items.is_a?(Array)

    assert_not reified_items.first.readonly?

    children_hash = reified_items.last

    assert children_hash.is_a?(Hash)

    assert children_hash.values.all?(&:readonly?)
  end

  def test_fetch_reified_items_with_sti_class
    post = SubPost.create!(a: 1, b: 2)
    comment_content = 'Example comment'
    post.comments.create!(content: comment_content)
    post.create_snapshot!(identifier: 'v1')
    snapshot = post.snapshots.first
    reified_items = snapshot.fetch_reified_items

    assert_equal post, reified_items.first
    assert reified_items.first.readonly?
    assert_equal comment_content, reified_items.second[:comments].first.content
  end

  def test_single_model_snapshots_without_children
    instance = ParentWithoutChildren.create!({a: 1, b: 2})

    prev_attrs = instance.attributes

    instance.create_snapshot!(identifier: 'v1')

    instance.update!(a: 9, b: 9)

    snapshot = instance.snapshots.first

    reified_items = snapshot.fetch_reified_items

    assert_equal [instance, {}], reified_items

    new_attrs = reified_items.first.attributes

    prev_time_attrs = prev_attrs.extract!("created_at","updated_at")
    new_time_attrs = new_attrs.extract!("created_at","updated_at")

    if ActiveSnapshot.config.storage_method_yaml?
      assert_equal new_time_attrs.values.map{|x| x.round(6)}, new_time_attrs.values
    else
      assert_equal new_time_attrs.values.map{|x| x.round(3)}, new_time_attrs.values
    end

    ### rounding to 3 sometimes fails due to millisecond precision so we just test for 2 decimal places here
    assert_equal prev_time_attrs.values.map{|x| x.round(2)}, new_time_attrs.values.map{|x| x.round(2)}
  end

end
