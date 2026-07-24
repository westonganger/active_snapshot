require "test_helper"

class PostgresSpecificTest < ActiveSupport::TestCase
  if defined?(PG)
    def setup
      @instance = ModelWithAllPostgresColumnTypes.new(
        text_field: "some-text",
        integer_field: 2,
        date_field: Date.parse("2026-06-03"),
        time_field: (Time.parse("2026-07-04 04:05:06") if !ActiveSnapshot.config.storage_method_yaml?),
        timestamp_field: Time.parse("2026-08-05 01:02:03"),
        binary_field: "0010010",
        boolean_field: true,
        json_field: {string: "bar", number: 2, array: [1,2,3]},
        jsonb_field: {string: "baz", number: 3, array: [2,3,4]},
        inet_field: "192.168.1.55",
        cidr_field: "192.168.10.0/24",
        mac_field: "08:00:2b:01:02:03",
        uuid_field: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        bit_field: "00001111",
        money_field: BigDecimal("49.99"),
        text_array_field: ["a","b","c"],
        integer_array_field: [1,2,3],
        enum_array_field: ["foo","bar"],
        enum_field: "bar",
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
        {
          text_field: "some-text",
          integer_field: 2,
          date_field: Date.parse("2026-06-03"),
          boolean_field: true,
          binary_field: "0010010",
          json_field: {"string" => "bar", "number" => 2, "array" => [1,2,3]},
          jsonb_field: {"string" => "baz", "number" => 3, "array" => [2,3,4]},
          inet_field: IPAddr.new("192.168.1.55"),
          cidr_field: IPAddr.new("192.168.10.0/24"),
          mac_field: "08:00:2b:01:02:03",
          uuid_field: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
          bit_field: "00001111",
          money_field: BigDecimal("49.99"),
          text_array_field: ["a","b","c"],
          integer_array_field: [1,2,3],
          enum_array_field: ["foo","bar"],
          enum_field: "bar",
        },
        snapshot_item.item.attributes.symbolize_keys.except(:id, :time_field, :timestamp_field)
      )

      assert_time_match(Time.parse("2026-08-05 01:02:03"), snapshot_item.item.timestamp_field)

      if !ActiveSnapshot.config.storage_method_yaml?
        assert_time_match(Time.parse("2000-01-01 04:05:06"), snapshot_item.item.time_field)
      end
    end

    def test_diff_handles_column_serialization
      snapshot = @instance.create_snapshot!

      @instance.assign_attributes(
        text_field: "other-text",
        integer_field: 3,
        date_field: Date.parse("2026-01-03"),
        time_field: (Time.parse("2026-07-04 07:08:09") if !ActiveSnapshot.config.storage_method_yaml?),
        timestamp_field: Time.parse("2026-03-05 04:05:06"),
        json_field: {string: "foo", number: 1, array: [4,5,6]},
        binary_field: "0101010101",
        boolean_field: false,
        jsonb_field: {string: "baz2", number: 4, array: [5,2,3,4]},
        inet_field: "192.168.1.52",
        cidr_field: "192.168.9.0/24",
        mac_field: "08:00:2b:01:02:04",
        uuid_field: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12",
        bit_field: "00011111",
        money_field: BigDecimal("39.99"),
        text_array_field: ["a","b","d"],
        integer_array_field: [1,2,4],
        enum_array_field: ["bar"],
        enum_field: "foo",
      )

      @instance.save!

      diff = ActiveSnapshot::Snapshot.diff(snapshot, @instance)

      assert_equal(["some-text","other-text"], diff.first[:changes][:text_field])
      assert_equal([2,3], diff.first[:changes][:integer_field])
      assert_equal([Date.parse("2026-06-03"), Date.parse("2026-01-03")], diff.first[:changes][:date_field])
      assert_equal([{"string" => "bar", "number" => 2, "array" => [1, 2, 3]}, {"string" => "foo", "number" => 1, "array" => [4, 5, 6]}], diff.first[:changes][:json_field])
      assert_equal(["0010010", "0101010101"], diff.first[:changes][:binary_field])
      assert_equal([true, false], diff.first[:changes][:boolean_field])
      assert_equal(["bar", "foo"], diff.first[:changes][:enum_field])
      assert_equal([{"string"=>"baz", "number"=>3, "array"=>[2, 3, 4]}, {"string"=>"baz2", "number"=>4, "array"=>[5, 2, 3, 4]}], diff.first[:changes][:jsonb_field])
      assert_equal([IPAddr.new("192.168.1.55"), IPAddr.new("192.168.1.52")], diff.first[:changes][:inet_field])
      assert_equal([IPAddr.new("192.168.10.0/24"), IPAddr.new("192.168.9.0/24")], diff.first[:changes][:cidr_field])
      assert_equal(["08:00:2b:01:02:03", "08:00:2b:01:02:04"], diff.first[:changes][:mac_field])
      assert_equal(["a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12"], diff.first[:changes][:uuid_field])
      assert_equal(["00001111", "00011111"], diff.first[:changes][:bit_field])
      assert_equal([BigDecimal("49.99"), BigDecimal("39.99")], diff.first[:changes][:money_field])
      assert_equal([["a", "b", "c"], ["a", "b", "d"]], diff.first[:changes][:text_array_field])
      assert_equal([[1, 2, 3], [1, 2, 4]], diff.first[:changes][:integer_array_field])
      assert_equal([["foo", "bar"], ["bar"]], diff.first[:changes][:enum_array_field])
      assert_equal(["bar", "foo"], diff.first[:changes][:enum_field])

      assert_time_match(Time.parse("2026-08-05 01:02:03"), diff.first[:changes][:timestamp_field].first)
      assert_time_match(Time.parse("2026-03-05 04:05:06"), diff.first[:changes][:timestamp_field].last)

      if !ActiveSnapshot.config.storage_method_yaml?
        assert_time_match(Time.parse("2000-01-01 04:05:06"), diff.first[:changes][:time_field].first)
        assert_time_match(Time.parse("2000-01-01 07:08:09"), diff.first[:changes][:time_field].last)
      end
    end
  end
end
