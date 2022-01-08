CHANGELOG
---------

- **UNRELEASED**
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.2.3...master)
  * Nothing yet

- **UNRELEASED**
  * [View Diff](https://github.com/westonganger/active_snapshot/compare/v0.2.2...v0.2.3)
  * Support Ruby 3.1
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
