require "test_helper"

class ErrorsTest < ActiveSupport::TestCase

  setup do
  end

  teardown do
  end

  def test_has_snapshot_children_errors
    klass = VolatilePost

    assert_raise ArgumentError do
      klass.has_snapshot_children
    end

    klass.has_snapshot_children do
      {}
    end

    klass.has_snapshot_children

    invalid = [
      "foobar",
      true,
      false,
      nil,
      "",
      [],
      [:foobar, 123],
      {foo: :bar},
      {foo: {}},
      {foo: {records: 'bar', delete_method: 'bar'}},
    ]

    invalid.each do |x|
      klass.has_snapshot_children do
        x
      end

      assert_raise ArgumentError do
        klass.has_snapshot_children
      end
    end

    valid = [
      {},
      {foo: []},
      {foo: [:foobar, 123]},
      {foo: {record: 'bar'}},
      {foo: {records: 'bar'}},
      {foo: {record: Post.limit(1) }},
      {foo: {records: Post.limit(1) }},
      {foo: {records: [], delete_method: ->(){} }},
      {foo: {records: [], delete_method: proc{} }},
    ]

    valid.each do |x|
      klass.has_snapshot_children do
        x
      end

      klass.has_snapshot_children
    end
  end

end
