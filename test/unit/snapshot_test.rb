require "test_helper"

class SnapshotTest < ActiveSupport::TestCase

  def setup
  end

  def teardown
  end

  def test_relationships
    post = Post.create!(a: 1, b: 3)

    snapshot = ActiveSnapshot::Snapshot.new

    assert snapshot.user.nil?
    assert snapshot.item.nil?
    assert snapshot.snapshot_items.empty?

    snapshot.user = snapshot
    snapshot.item = snapshot

    assert_raises do
      snapshot.snapshot_items << snapshot
    end

    snapshot.snapshot_items << ActiveSnapshot::SnapshotItem.new

    assert_not snapshot.user.nil?
    assert_not snapshot.item.nil?
    assert_not snapshot.snapshot_items.empty?

    snapshot = ActiveSnapshot::Snapshot.new(item: post, user: post)

    assert snapshot.item.id, post.id
    assert snapshot.user.id, post.id
  end

  def test_validates_item_presence
    snapshot = ActiveSnapshot::Snapshot.new

    assert_not snapshot.valid?

    [:item_id, :item_type].each do |attr|
      assert snapshot.errors[attr].present? ### presence error
    end
  end

  def test_validates_identifier_uniqueness
    post = Post.create!(a: 1, b: 3)
    post.create_snapshot!(identifier: "v1")

    exception = assert_raises(ActiveRecord::RecordInvalid) do
      post.create_snapshot!(identifier: "v1")
    end

    assert_equal "Validation failed: Identifier has already been taken", exception.message

    post.create_snapshot!(identifier: "v2")
  end

  def test_metadata
    post = Post.create!(a: 1, b: 3)
    snapshot = post.create_snapshot!(identifier: "v1")

    assert snapshot.metadata.is_a?(Hash)

    snapshot.metadata = {foo: :bar}

    if ActiveSnapshot.config.storage_method_yaml?
      assert_equal :bar, snapshot.metadata.fetch(:foo)
    else
      assert_equal "bar", snapshot.metadata.fetch("foo")
    end
  end

  def test_build_snapshot_item
    post = Post.create!(a: 1, b: 3)
    snapshot = post.create_snapshot!(identifier: "v1")

    snapshot_item = snapshot.build_snapshot_item(Post.create!(a: 1, b: 3))

    assert snapshot_item.is_a?(ActiveSnapshot::SnapshotItem)

    assert snapshot_item.new_record?

    assert_equal snapshot.id, snapshot_item.snapshot_id

    snapshot.build_snapshot_item(Post.create!(a: 1, b: 3), child_group_name: :foobar)
  end

  def test_snapshot_item_stores_enum_column_database_value
    assert Post.defined_enums.has_key?("status")

    post = Post.create!(a: 1, b: 3)

    enum_mapping = post.class.defined_enums.fetch("status")

    post.status = "published"

    snapshot = post.create_snapshot!(identifier: "enum-test")

    snapshot_item = snapshot.snapshot_items.find_by(item_type: "Post")

    stored_value = snapshot_item.object["status"]

    assert_equal 1, stored_value
    assert_equal "published", enum_mapping.key(stored_value)
  end

  def test_snapshot_item_handles_nil_enum_column_value
    assert Post.defined_enums.has_key?("status")

    post = Post.create!(a: 1, b: 3)

    post.status = nil

    snapshot = post.create_snapshot!(identifier: "enum-test")

    snapshot_item = snapshot.snapshot_items.find_by(item_type: "Post")

    stored_value = snapshot_item.object["status"]

    assert_nil stored_value
  end

  def test_snapshot_item_handles_enum_values_from_select_statement
    assert Post.defined_enums.has_key?("status")

    assert_equal "draft", Post.create!(a: 1, b: 3).status

    Post.create!(a: 1, b: 3)

    post = Post.select(:id).first!

    snapshot = post.create_snapshot!(identifier: "enum-test")

    snapshot_item = snapshot.snapshot_items.find_by(item_type: "Post")

    stored_value = snapshot_item.object["status"]

    assert_nil stored_value
  end

  def test_fetch_reified_items_reifies_enum_stored_as_database_value
    assert Post.defined_enums.has_key?("status")

    post = Post.create!(a: 1, b: 3)

    post.status = "published"

    snapshot = post.create_snapshot!(identifier: "enum-test")

    reified_post = snapshot.fetch_reified_items[0]

    assert_equal "published", reified_post.status
  end

  def test_fetch_reified_items_reifies_enum_stored_as_label
    ### Snapshots created with gem versions <= 0.4.x stored enum attributes as their label
    assert Post.defined_enums.has_key?("status")

    post = Post.create!(a: 1, b: 3)

    post.status = "published"

    snapshot = post.create_snapshot!(identifier: "enum-test")

    snapshot_item = snapshot.snapshot_items.find_by(item_type: "Post")
    snapshot_item.object = snapshot_item.object.merge("status" => "published")
    snapshot_item.save!

    reified_post = snapshot.reload.fetch_reified_items[0]

    assert_equal "published", reified_post.status
  end

  def test_restore
    post = Post.create!(a: 1, b: 3)
    snapshot = post.create_snapshot!(identifier: "v1")

    assert_nothing_raised do
      snapshot.restore!
    end
  end

  def test_fetch_reified_items_with_readonly
    post = Post.create!(a: 1, b: 3)
    snapshot = post.create_snapshot!(identifier: "v1")

    reified_items = snapshot.fetch_reified_items

    assert reified_items.is_a?(Array)

    assert reified_items.first.readonly?

    children_hash = reified_items.last

    assert children_hash.is_a?(Hash)

    assert children_hash.values.all?(&:readonly?)
  end

  def test_fetch_reified_items_without_readonly
    post = Post.create!(a: 1, b: 3)
    snapshot = post.create_snapshot!(identifier: "v1")

    reified_items = snapshot.fetch_reified_items(readonly: false)

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

    snapshot = post.create_snapshot!(identifier: 'v1')

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

    snapshot = post.create_snapshot!(identifier: 'v1')

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

    snapshot = post.create_snapshot!(identifier: 'v1')

    reified_post, reified_children = snapshot.fetch_reified_items

    assert_equal post, reified_post
    assert reified_post.readonly?
    assert_equal ['comments'], reified_children.keys
    assert_equal comment_content, reified_children['comments'].first.content
  end

  def test_fetch_reified_items_handles_dropped_columns!
    post = Post.create!(a: 1, b: 3)
    snapshot = post.create_snapshot!(identifier: "v1")

    snapshot_item = snapshot.snapshot_items.first!

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

    snapshot = instance.create_snapshot!(identifier: 'v1')

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

  def test_snapshot_with_identical_children_at_different_relations
    user = User.create!(name: "Example User")

    task = Task.create!(
      title: "Example Task",
      requester: user,
      assignee: user,
    )

    snapshot = task.create_snapshot!

    items = snapshot.snapshot_items.order(:id)
    assert_equal ["Task", "User", "User"], items.map(&:item_type)
    assert_equal user.id, items[1].item_id
    assert_equal user.id, items[2].item_id
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
    post.comments.create!(content: "First comment")
    post.comments.create!(content: "Comment to destroy")
    from_snapshot = post.create_snapshot!

    post.update!(a: 3, b: 4)
    destroyed_comment = post.comments.last.destroy!
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
    assert_equal destroyed_comment.id, destroy_diff[:item_id]
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

  def test_snapshot_item_stores_encrypted_attribute_as_ciphertext
    plaintext = "super secret comment"
    post = Post.create!(a: 1, b: 2)
    comment = post.comments.create!(content: plaintext)

    snapshot = post.create_snapshot!

    snapshot_item = snapshot.snapshot_items.find_by(item_type: "Comment", item_id: comment.id)

    raw_value = ActiveRecord::Base.connection.select_value(
      "SELECT object FROM snapshot_items WHERE id = #{snapshot_item.id}"
    )
    refute_includes raw_value.to_s, plaintext,
      "Expected encrypted attribute to be stored as ciphertext, not plaintext"

    stored_object = snapshot_item.object
    assert stored_object["content"].present?,
      "Expected ciphertext to be present"
  end

  def test_fetch_reified_items_decrypts_encrypted_attributes
    plaintext = "reify me correctly"
    post = Post.create!(a: 1, b: 2)
    post.comments.create!(content: plaintext)

    snapshot = post.create_snapshot!

    _reified_post, reified_children = snapshot.fetch_reified_items

    reified_comment = reified_children["comments"].first
    assert_equal plaintext, reified_comment.content
  end

  def test_restore_preserves_encrypted_attribute_value
    original_content = "original secret"
    post = Post.create!(a: 1, b: 2)
    comment = post.comments.create!(content: original_content)

    snapshot = post.create_snapshot!

    comment.update!(content: "changed secret")
    assert_equal "changed secret", comment.reload.content

    snapshot.restore!

    comment.reload
    assert_equal original_content, comment.content

    raw_value = ActiveRecord::Base.connection.select_value(
      "SELECT content FROM comments WHERE id = #{comment.id}"
    )
    refute_equal original_content, raw_value,
      "Expected DB column to contain ciphertext after restore, not plaintext"
  end

  def test_snapshot_handles_nil_encrypted_attribute
    post = Post.create!(a: 1, b: 2)
    comment = post.comments.create!(content: nil)

    snapshot = post.create_snapshot!

    snapshot_item = snapshot.snapshot_items.find_by(item_type: "Comment", item_id: comment.id)
    assert_nil snapshot_item.object["content"]

    _reified_post, reified_children = snapshot.fetch_reified_items
    assert_nil reified_children["comments"].first.content
  end

  def test_snapshot_backward_compat_plaintext_encrypted_attribute
    plaintext = "old plaintext from before encryption patch"
    post = Post.create!(a: 1, b: 2)
    comment = post.comments.create!(content: "placeholder")

    snapshot = post.create_snapshot!

    snapshot_item = snapshot.snapshot_items.find_by(item_type: "Comment", item_id: comment.id)
    obj = snapshot_item.object
    obj["content"] = plaintext
    snapshot_item.update!(object: obj)

    _reified_post, reified_children = snapshot.fetch_reified_items
    reified_comment = reified_children["comments"].first
    assert_equal plaintext, reified_comment.content
  end

end
