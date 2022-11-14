CHANGELOG
---------

- **Unreleased**
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.3.0...master)
  - Nothing yet

- **v0.3.0** - November 14, 2022
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.2.4...v0.3.0)
  * [PR #24](https://github.com/westonganger/active_snapshot/pull/24) - Fix arguments for db migration for mysql
  * [PR #29](https://github.com/westonganger/active_snapshot/pull/29) - Deprecate :identifier argument as a positional argument
  * [PR #30](https://github.com/westonganger/active_snapshot/pull/30) - Make snapshot identifier optional
  * [PR #32](https://github.com/westonganger/active_snapshot/pull/26) - Add configuration option `ActiveSnapshot.config.storage_method = 'serialized_json'` with support for `serialized_json`, `serialized_yaml`, `native_json`
  * [PR #32](https://github.com/westonganger/active_snapshot/pull/32) - Change default storage method from `serialized_yaml` to `serialized_json`. 
  * [PR #32](https://github.com/westonganger/active_snapshot/pull/32) - `snapshot.metadata` and `snapshot_item.object` no longer return a HashWithIndifferentAccess. Now they simply return a regular Hash.
  * **Upgrade Instructions**
    * Change all instances of `create_snapshot!("my-snapshot-1"` to `create_snapshot!(identifier: "my-snapshot-1"`
    * Create a migration with the following `change_column_null :snapshots, :identifier, true` to remove the null constraint here
    * If you have existing snapshots from a previous version then please set `ActiveSnapshot.config.storage_method = "serialized_yaml"`

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
