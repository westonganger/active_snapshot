require "test_helper"

class SerializedColumnsTest < ActiveSupport::TestCase
  def setup
    @instance = ModelWithSerializedColumns.new(
      yaml_field: {number: 2, foo: "some-foo", bar: "some-bar", nested: {bar: "some-bar", baz: "some-nested-baz"}, timestamp: Time.parse("2026-02-03")},
      json_field: {json: true, number: 2, foo: "some-foo", bar: "some-bar", nested: {bar: "some-bar", baz: "some-nested-baz"}, timestamp: Time.parse("2026-02-03")},
    )

    @instance.save!
  end

  def teardown
  end

  def test_restore_snapshot_handles_column_serialization
    snapshot = @instance.create_snapshot!

    snapshot_item = snapshot.snapshot_items.first!

    snapshot_item.restore_item!

    assert_equal(
      {number: 2, foo: "some-foo", bar: "some-bar", nested: {bar: "some-bar", baz: "some-nested-baz"}, timestamp: Time.parse("2026-02-03")},
      snapshot_item.item.yaml_field
    )

    assert_equal(
      {"json" => true, "number" => 2, "foo" => "some-foo", "bar" => "some-bar", "nested" => {"bar" => "some-bar", "baz" => "some-nested-baz"}, "timestamp" => "2026-02-03T00:00:00.000+00:00"}.stringify_keys,
      snapshot_item.item.json_field
    )
  end

  def test_diff_handles_column_serialization
    snapshot = @instance.create_snapshot!

    @instance.yaml_field = {foo: "bar"}
    @instance.json_field = {bar: "baz"}

    diff = ActiveSnapshot::Snapshot.diff(snapshot, @instance)

    assert_equal(
      {
        yaml_field: [
          {
            number: 2,
            foo: "some-foo",
            bar: "some-bar",
            nested: {
              bar: "some-bar",
              baz: "some-nested-baz"
            },
            timestamp: Time.parse("2026-02-03")
          },
          {foo: "bar"}
        ],
        json_field: [
          {
            "json" => true,
            "number" => 2,
            "foo" => "some-foo",
            "bar" => "some-bar",
            "nested" => {
              "bar" => "some-bar",
              "baz" => "some-nested-baz"
            },
            "timestamp" => "2026-02-03T00:00:00.000+00:00"
          },
          {"bar" => "baz"}
        ]
      },
      diff.first[:changes]
    )
  end
end
