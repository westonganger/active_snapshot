# ActiveSnapshot

<a href="https://badge.fury.io/rb/active_snapshot" target="_blank"><img height="21" style='border:0px;height:21px;' border='0' src="https://badge.fury.io/rb/active_snapshot.svg" alt="Gem Version"></a>
<a href='https://travis-ci.com/westonganger/active_snapshot' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://api.travis-ci.org/westonganger/active_snapshot.svg?branch=master' border='0' alt='Build Status' /></a>
<a href='https://rubygems.org/gems/active_snapshot' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://ruby-gem-downloads-badge.herokuapp.com/active_snapshot?label=rubygems&type=total&total_label=downloads&color=brightgreen' border='0' alt='RubyGems Downloads' /></a>

Dead simple snapshot versioning for ActiveRecord models and associations. I created this as simpler and less invasive alternative to PaperTrail and PaperTrailAssociationTracking.

Key Features:

- Create and Restore snapshots of a parent record and any specified child records
- Predictible and explicit behaviour provides much needed clarity to your restore logic as opposed to the black hole that is PaperTrailAssociationTracking
- Tiny method footprint so its easy to completely override the logic later

## Installation

```ruby
# Gemfile

gem 'active_snapshot'
```

Then generate and run the necessary migrations to setup the `active_snapshot_versions` table

```
rails generate active_snapshot:install
rake db:migrate
```

## Usage

```ruby
post = Post.first

child_records = []
post.comments.each do |comment|
  child_records << comment
end

# Create snapshot grouped by identifier
parent_snapshot_version = post.active_snapshot.create_snapshot!("snapshot_1", child_records: child_records, metadata: {foo: :bar})

# Restore snapshot and all its child snapshots
post.active_snapshot.restore_snapshot!(parent_snapshot_version)

# Destroy snapshot and all its child snapshots
post.active_snapshot.destroy_snapshot!(parent_snapshot_version)

# Create individual snapshot version
post.active_snapshot.create_version!(identifier: "snapshot_2", metadata: {foo: :bar})
```

# Credits

Created & Maintained by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)
