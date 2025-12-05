require "test_helper"

class SnapshotTest < ActiveSupport::TestCase

  def setup
    @snapshot_klass = ActiveSnapshot::Snapshot
  end

  def teardown
  end

  def test_relationships
    shared_post = Post.first!

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
    shared_post = Post.first!
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

    assert_nothing_raised do
      @snapshot.restore!
    end
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

  def test_fetch_reified_items_with_base_class
    post = Post.create!(a: 1, b: 2)

    comment_content = 'Example comment'
    post.comments.create!(content: comment_content)

    note_body = 'Example note'
    post.notes.create!(body: note_body)

    post.create_snapshot!(identifier: 'v1')
    snapshot = post.snapshots.first

    reified_post, reified_children = snapshot.fetch_reified_items

    assert_equal post, reified_post
    assert reified_post.readonly?
    assert_equal ['comments', 'notes'], reified_children.keys.sort
    assert_equal comment_content, reified_children['comments'].first.content
    assert_equal note_body, reified_children['notes'].first.body
  end

  def test_fetch_reified_items_with_sti_class
    # Inherits snapshot children definition from base class
    post = SubPost.create!(a: 1, b: 2)

    comment_content = 'Example comment'
    post.comments.create!(content: comment_content)

    note_body = 'Example note'
    post.notes.create!(body: note_body)

    post.create_snapshot!(identifier: 'v1')
    snapshot = post.snapshots.first

    reified_post, reified_children = snapshot.fetch_reified_items

    assert_equal SubPost, reified_post.class
    assert_equal post, reified_post
    assert reified_post.readonly?
    assert_equal ['comments', 'notes'], reified_children.keys.sort
    assert_equal comment_content, reified_children['comments'].first.content
    assert_equal note_body, reified_children['notes'].first.body
  end

  def test_fetch_reified_items_with_sti_class_having_own_definition
    # Includes "comments" children, but no "notes"
    post = SubPostWithOwnDefinition.create!(a: 1, b: 2)

    comment_content = 'Example comment'
    post.comments.create!(content: comment_content)

    note_body = 'Example note'
    post.notes.create!(body: note_body)

    post.create_snapshot!(identifier: 'v1')
    snapshot = post.snapshots.first

    reified_post, reified_children = snapshot.fetch_reified_items

    assert_equal post, reified_post
    assert reified_post.readonly?
    assert_equal ['comments'], reified_children.keys
    assert_equal comment_content, reified_children['comments'].first.content
  end

  def test_fetch_reified_items_handles_dropped_columns!
    snapshot = @snapshot_klass.first

    snapshot_item = snapshot.snapshot_items.first

    attrs = snapshot_item.object
    attrs["foo"] = "bar"

    snapshot_item.update!(object: attrs)

    assert_nothing_raised do
      snapshot.fetch_reified_items(readonly: false)
    end
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

    diff = ActiveSnapshot::Snapshot.diff(from_snapshot, to_snapshot)

    assert_equal 3, diff.length

    # Test update
    update_diff = diff.find { |d| d[:action] == :update }
    assert_equal :update, update_diff[:action]
    assert_equal post.id, update_diff[:item_id]
    assert_equal "Post", update_diff[:item_type]
    assert_equal [1, 3], update_diff[:changes][:a]
    assert_equal [2, 4], update_diff[:changes][:b]

    # Test destroy
    destroy_diff = diff.find { |d| d[:action] == :destroy }
    assert_equal :destroy, destroy_diff[:action]
    assert_equal comment_to_destroy.id, destroy_diff[:item_id]
    assert_equal "Comment", destroy_diff[:item_type]
    assert_equal ["Comment to destroy", nil], destroy_diff[:changes][:content]

    # Test create
    create_diff = diff.find { |d| d[:action] == :create }
    assert_equal :create, create_diff[:action]
    assert_equal new_comment.id, create_diff[:item_id]
    assert_equal "Comment", create_diff[:item_type]
    assert_equal [nil, "New comment"], create_diff[:changes][:content]

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

    diff = ActiveSnapshot::Snapshot.diff(from_snapshot, post)

    assert_equal 3, diff.length

    update_diff = diff.find { |d| d[:action] == :update }
    assert_equal :update, update_diff[:action]
    assert_equal post.id, update_diff[:item_id]
    assert_equal "Post", update_diff[:item_type]
    assert_equal [1, 3], update_diff[:changes][:a]
    assert_equal [2, 4], update_diff[:changes][:b]

    destroy_diff = diff.find { |d| d[:action] == :destroy }
    assert_equal :destroy, destroy_diff[:action]
    assert_equal comment_to_destroy.id, destroy_diff[:item_id]
    assert_equal "Comment", destroy_diff[:item_type]
    assert_equal ["Comment to destroy", nil], destroy_diff[:changes][:content]

    create_diff = diff.find { |d| d[:action] == :create }
    assert_equal :create, create_diff[:action]
    assert_equal new_comment.id, create_diff[:item_id]
    assert_equal "Comment", create_diff[:item_type]
    assert_equal [nil, "New comment"], create_diff[:changes][:content]
  end

  def test_diff_between_snapshot_and_sti_instance
    post = SubPost.create!(a: 1, b: 2)
    from_snapshot = post.create_snapshot!

    post.update!(a: 3, b: 4)
    diff = ActiveSnapshot::Snapshot.diff(from_snapshot, post)

    update_diff = diff.find { |d| d[:action] == :update }
    assert_equal :update, update_diff[:action]
    assert_equal post.id, update_diff[:item_id]
    assert_equal "SubPost", update_diff[:item_type]
    assert_equal [1, 3], update_diff[:changes][:a]
    assert_equal [2, 4], update_diff[:changes][:b]
  end

  def test_diff_argument_error_when_from_is_not_a_snapshot
    post = Post.create!
    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(post, post)
    end
  end

  def test_diff_argument_error_when_from_and_to_are_not_the_same_item
    post1 = Post.create!
    snapshot1 = post1.create_snapshot!
    post2 = Post.create!
    snapshot2 = post2.create_snapshot!

    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(snapshot1, snapshot2)
    end
  end

  def test_diff_argument_error_when_from_and_to_are_not_the_same_item_and_one_is_an_instance
    post1 = Post.create!
    snapshot1 = post1.create_snapshot!
    post2 = Post.create!

    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(snapshot1, post2)
    end
  end

  def test_diff_argument_error_when_from_is_not_newer_than_to
    post = Post.create!
    snapshot1 = post.create_snapshot!
    post.update!(a: 1)

    snapshot2 = post.create_snapshot!

    assert_raises(ArgumentError) do
      ActiveSnapshot::Snapshot.diff(snapshot2, snapshot1)
    end
  end

end
