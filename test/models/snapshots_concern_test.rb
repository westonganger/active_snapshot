require "test_helper"

class SnapshotsConcernTest < ActiveSupport::TestCase

  def setup
  end

  def teardown
  end

  def test_relationships
    instance = Post.new

    assert instance.snapshots.empty?
    assert instance.snapshot_items.empty?

    assert_raises do
      instance.snapshots << instance
    end

    instance.snapshots << ActiveSnapshot::Snapshot.new

    assert_raises do
      instance.snapshot_items << instance
    end

    instance.snapshot_items << ActiveSnapshot::SnapshotItem.new

    assert_not instance.snapshots.empty?
    assert_not instance.snapshot_items.empty?
  end

  def test_create_snapshot!
    @post = Post.first

    #@user = User.first

    snapshot = @post.create_snapshot!(identifier: "foobar 1", user: @user, metadata: {foo: :bar})
    assert_not snapshot.new_record?

    snapshot = @post.create_snapshot!(identifier: "foobar 2", user: @user)
    assert_not snapshot.new_record?

    snapshot = @post.create_snapshot!(identifier: "foobar 3")
    assert_not snapshot.new_record?

    assert_raise do
      @post.create_snapshot!(identifier: "foobar 3")
    end
  end

  def test_has_snapshot_children
    klass = VolatilePost
    
    assert_nil klass.has_snapshot_children

    klass.has_snapshot_children do
      {}
    end

    assert klass.instance_variable_get(:@snapshot_children_proc).is_a?(Proc)

    klass.new.children_to_snapshot

    invalid = [
      "foobar",
      true,
      false,
      nil,
      "",
      [],
      [:foobar, 123],
      {foo: :bar},
      {foo: {records: 'bar', delete_method: 'bar'}},
    ]

    invalid.each do |x|
      klass.has_snapshot_children do
        x
      end

      assert_raise ArgumentError do
        klass.new.children_to_snapshot
      end
    end

    valid = [
      {},
      {foo: []},
      {foo: {}},
      {foo: Post.limit(1)},
      {foo: [:foobar, 123]},
      {foo: {record: 'bar'}},
      {foo: {records: 'bar'}},
      {foo: {record: Post.limit(1) }},
      {foo: {records: Post.limit(1) }},
      {foo: {records: [], delete_method: ->(){} }},
      {foo: {records: [], delete_method: proc{} }},
      {foo: nil},
      {foo: {records: nil}},
    ]

    valid.each do |x|
      klass.has_snapshot_children do
        x
      end

      klass.new.children_to_snapshot
    end

    klass.has_snapshot_children do
      {foo: {records: 'bar'}, baz: {records: 'barbaz'}}
    end

    assert klass.new.children_to_snapshot.count == 2
  end

  def test_legacy_positional_identifier_argument
    call_count = 0

    allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).and_wrap_original do |m, *args|
      if args.first == ActiveSnapshot::SnapshotsConcern::LEGACY_POSITIONAL_ARGUMENT_WARNING
        call_count += 1
      end
    end

    assert_difference ->{ ActiveSnapshot::Snapshot.count }, 1 do
      @snapshot = Post.first.create_snapshot!("snapshot-1")
    end

    assert_equal call_count, 1
  end

  def test_optional_identifier
    post = Post.first

    assert_difference ->{ ActiveSnapshot::Snapshot.count }, 2 do
      post.create_snapshot!
      post.create_snapshot!
    end
  end

end
