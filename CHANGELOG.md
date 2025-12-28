CHANGELOG
---------

- **Unreleased**
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v1.1.0...master)
  * Nothing yet

- **v1.1.0** - Dec 28 2025
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v1.0.0...v1.1.0)
  * [#77](https://github.com/westonganger/active_snapshot/pull/77) - Remove uniqueness constraint from `snapshot_items` table migration
    - Upgrade Instructions: Create a DB migration with `remove_index :snapshot_items, [:snapshot_id, :item_id, :item_type], unique: true`
  * [#76](https://github.com/westonganger/active_snapshot/pull/76) - Add full STI support (inherit snapshot children definition from base class, and allow overriding in STI child classes)
  * [#74](https://github.com/westonganger/active_snapshot/pull/74) - Ensure no exception is raised when class does not have method defined_enums
  * [#72](https://github.com/westonganger/active_snapshot/pull/72) - Adds `ActiveSnapshot::Snapshot.diff(from, to)` to get the difference between two snapshots or a snapshot and the current record.

- **v1.0.0** - Jan 17 2025
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.5.2...v1.0.0)
  * There are no functional changes. This release v1.0.0 is to signal that its stable and ready for widespread usage.

- **v0.5.2** - Nov 11, 2024
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.5.1...v0.5.2)
  * [#67](https://github.com/westonganger/active_snapshot/pull/67) - Switch default storage method to native SQL JSON columns. No longer recommend to set `ActiveSnapshot.config.storage_method`, this configuration option is only retained to support legacy installations which utilize serialized YAML or serialized JSON text columns. The default storage method will fallback gracefully for legacy installations, if there already exists a text column then it defaults to `ActiveSnapshot.config.storage_method = "serialized_json"`
  * Drop support for Rails 6.0. Rails 6.1 is minimum required version now.

- **v0.5.1** - Nov 11, 2024
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.5.0...v0.5.1)
  * [#66](https://github.com/westonganger/active_snapshot/pull/66) - Ensure `SnapshotItem#restore_item!` and `Snapshot#fetch_reified_items` bypass assignment for snapshot object data where the associated column no longer exists.
  * [#63](https://github.com/westonganger/active_snapshot/pull/63) - Fix bug when enum value is nil

- **v0.5.0** - Nov 8, 2024
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.4.0...v0.5.0)
  * [#61](https://github.com/westonganger/active_snapshot/pull/61) - Ensure snapshot record returned by `create_snapshot!` is `valid?`
  * [#60](https://github.com/westonganger/active_snapshot/pull/60) - Store enum value as integer
  * [#56](https://github.com/westonganger/active_snapshot/pull/56) - Add presence validation for object in SnapshotItem model
  * [#57](https://github.com/westonganger/active_snapshot/pull/57) - Add readonly argument to `Shapshot#fetch_reified_items`
  * [#53](https://github.com/westonganger/active_snapshot/pull/53) - Allow `ActiveSnapshot.config` to be called before ActiveRecord `on_load` hook has occurred
  * [#52](https://github.com/westonganger/active_snapshot/pull/52) - Remove deprecated positional argument on `create_snapshot!`

- **v0.4.0** - July 23, 2024
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.3.2...v0.4.0)
  * [#44](https://github.com/westonganger/active_snapshot/pull/44) - Remove dependency on `activerecord-import` with vanilla ActiveRecord `upsert_all`

- **v0.3.2** - Oct 17, 2023
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.3.1...v0.3.2)
  * [#43](https://github.com/westonganger/active_snapshot/pull/43) - Fix unique index error in generated DB migration

- **v0.3.1** - August 4, 2023
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.3.0...v0.3.1)
  * [#36](https://github.com/westonganger/active_snapshot/pull/36) - Allow ActiveRecord to be lazy loaded using `ActiveSupport.on_load`
  * [#35](https://github.com/westonganger/active_snapshot/pull/35) - Add `optional: true` to the Snapshot `belongs_to :user` relationship
  * [#39](https://github.com/westonganger/active_snapshot/pull/39) - Remove redundant validation on SnapshotItem for item_type

- **v0.3.0** - November 14, 2022
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.2.4...v0.3.0)
  * [PR #24](https://github.com/westonganger/active_snapshot/pull/24) - Fix arguments for db migration for mysql
  * [PR #29](https://github.com/westonganger/active_snapshot/pull/29) - Deprecate :identifier argument as a positional argument
  * [PR #30](https://github.com/westonganger/active_snapshot/pull/30) - Make snapshot identifier optional
  * [PR #32](https://github.com/westonganger/active_snapshot/pull/26) - Add configuration option `ActiveSnapshot.config.storage_method = 'serialized_json'` with support for `serialized_json`, `serialized_yaml`, `native_json`
  * [PR #32](https://github.com/westonganger/active_snapshot/pull/32) - Change default storage method from `serialized_yaml` to `serialized_json`.
  * [PR #32](https://github.com/westonganger/active_snapshot/pull/32) - `snapshot.metadata` and `snapshot_item.object` no longer return a HashWithIndifferentAccess. Now they simply return a regular Hash.
  * **Upgrade Instructions**
    * Change all instances of `create_snapshot!("my-snapshot-1"` to `create_snapshot!(identifier: "my-snapshot-1")`
    * Create a migration with the following `change_column_null :snapshots, :identifier, true` to remove the null constraint here
    * If you have existing snapshots from a previous version then please set `ActiveSnapshot.config.storage_method = "serialized_yaml"` in an initializer

- **v0.2.4** - Feb 25, 2022
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.2.3...v0.2.4)
  * [PR #20](https://github.com/westonganger/active_snapshot/pull/20) - Resolve error when `has_snapshot_children` has not been defined as it should be optional
  * [PR #18](https://github.com/westonganger/active_snapshot/pull/18) - Fix bug where sub-classes of a model would not be assigned correctly as parent when restoring

- **v0.2.3** - Jan 7, 2022
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.2.2...v0.2.3)
  * Support Ruby 3.1 using `YAML.unsafe_load`
  * Fix unique constraint on snapshots.identifier column

- **v0.2.2** - August 27, 2021
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.2.1...v0.2.2)
  * [0715279](https://github.com/westonganger/active_snapshot/commit/0715279) - Fix bug on restore for in `has_snapshot_children` method with nil association values

- **v0.2.1** - August 19, 2021
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.2.0...v0.2.1)
  * [76b6bd9](https://github.com/westonganger/active_snapshot/commit/76b6bd951f73b277891976c458a0cdef0bd77af5) - Improve `has_snapshot_children` method to support single records and nil values which can occur with has_one/belongs_to relationships
  * [PR #7](https://github.com/westonganger/active_snapshot/pull/7) - Allow `has_snapshot_children` to be undefined for tracking only top level changes.

- **v0.2.0** - May 7, 2021
  * [PR #1](https://github.com/westonganger/active_snapshot/pull/1) - Fix bug where only the first child association would be captured
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.1.1...v0.2.0)

- **v0.1.1** - Mar 5, 2021
  * Switch from JSON to Text because Mysql2 has errors with active_record-import and JSON objects
  * Fix test suite
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.1.0...v0.1.1)
  * Nothing yet

- **v0.1.0** - Mar 5, 2021
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/edbbfd3...v0.1.0)
  * Gem Initial Release
