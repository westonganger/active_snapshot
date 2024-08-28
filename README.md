# ActiveSnapshot

<a href="https://badge.fury.io/rb/active_snapshot" target="_blank"><img height="21" style='border:0px;height:21px;' border='0' src="https://badge.fury.io/rb/active_snapshot.svg" alt="Gem Version"></a>
<a href='https://github.com/westonganger/active_snapshot/actions' target='_blank'><img src="https://github.com/westonganger/active_snapshot/actions/workflows/test.yml/badge.svg?branch=master" style="max-width:100%;" height='21' style='border:0px;height:21px;' border='0' alt="CI Status"></a>
<a href='https://rubygems.org/gems/active_snapshot' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://img.shields.io/gem/dt/active_snapshot?color=brightgreen&label=Rubygems%20Downloads' border='0' alt='RubyGems Downloads' /></a>

Simplified snapshots and restoration for ActiveRecord models and associations with a transparent white-box implementation.

Key Features:

- Create and Restore snapshots of a parent record and any specified child records
- Predictible and explicit behaviour provides much needed clarity to your restore logic
- Snapshots are created upon request only, we do not use any callbacks
- Tiny method footprint so its easy to completely override the logic later

Why This Library:

Model Versioning and Restoration require concious thought, design, and understanding. You should understand your versioning and restoration process completely. This gem's small API and fully understandable design fully supports this.

I do not recommend using paper_trail-association_tracking because it is mostly a blackbox solution which encourages you to set it up and then assume its Just Working<sup>TM</sup>. This makes for major data problems later. Dont fall into this trap. Instead read this gems brief source code completely before use OR copy the code straight into your codebase. Once you know it, then you are free.



# Installation

```ruby
gem 'active_snapshot'
```

Then generate and run the necessary migrations to setup the `snapshots` and `snapshot_items` tables.

```
rails generate active_snapshot:install
rake db:migrate
```

Then add `include ActiveSnapshot` to your ApplicationRecord or individual models.

```ruby
class ApplicationRecord < ActiveRecord::Base
  include ActiveSnapshot
end
```

This defines the following associations on your models:

```ruby
has_many :snapshots, as: :item, class_name: 'Snapshot'
has_many :snapshot_items, as: :item, class_name: 'SnapshotItem'
```

It defines an optional extension to your model: `has_snapshot_children`.

It defines one instance method to your model: `create_snapshot!`

# Using a different storage format

By default ActiveSnapshot encodes objects to JSON and stores in the database as plain text. If you prefer to have YAML encoded columns or native JSON DB columns you can configure this as follows:

```ruby
ActiveSnapshot.config do |config|
  config.storage_method = "serialized_json" # default, for text column
  #config.storage_method = "serialized_yaml" # for text column
  #config.storage_method = "native_json" # for json/jsonb column
end
```

If using a native json column, you should configure the `storage_method` before generating the migration. If this step was missed then you would need to create a migration to change the `:object` and `:metadata` columns to json (or jsonb)

```ruby
change_column :snapshots, :object, :json
change_column :snapshots, :metadata, :json
```

# Basic Usage

You now have access to the following methods:

```ruby
post = Post.first

# Create snapshot, all fields are optional
snapshot = post.create_snapshot!(
  identifier: "snapshot_1",
  user: current_user,
  metadata: {
    foo: :bar
  },
)

# Restore snapshot and all its child snapshots
snapshot.restore!

# Destroy snapshot and all its child snapshots
# must be performed manually, snapshots and snapshot items are NEVER destroyed automatically
snapshot.destroy!
```

# Tracking Associated / Child Records

```ruby
class Post < ActiveRecord::Base
  include ActiveSnapshot

  has_snapshot_children do
    ### Executed in the context of the instance / self

    ### Reload record from database to ensure a clean state and eager load the specified associations
    instance = self.class.includes(:tags, :ip_address, comments: [:comment_sub_records]).find(id)

    ### Define the associated records that will be restored
    {
      comments: instance.comments,

      ### Nested Associations can be handled by simply mapping them into an array
      comment_sub_records: instance.comments.flat_map{|x| x.comment_sub_records },

      tags: {
        records: instance.tags
      },

      ip_address: {
        record: instance.ip_address,
        delete_method: ->(item){ item.release! }
      }
    }
  end

end
```

Now when you run `create_snapshot!` the associations will be tracked accordingly

# Reifying Snapshot Items

You can view all of the reified snapshot items by calling the following method. Its completely up to you on how to use this data.

```ruby
reified_parent, reified_children_hash = snapshot.fetch_reified_items
```

As a safety these records have the `readonly` attribute set on them.
If you want to perform any write actions on the returned instances you will have to set the `readonly` attribute to `false`

```ruby
reified_parent, reified_children_hash = snapshot.fetch_reified_items(readonly: false)
# or
reified_parent, reified_children_hash = snapshot.fetch_reified_items
reified_children_hash.first.instance_variable_set("@readonly", false)
```

# Key Models Provided & Additional Customizations

A key aspect of this library is its simplicity and small API. For major functionality customizations we encourage you to first delete this gem and then copy this gems code directly into your repository.

I strongly encourage you to read the code for this library to understand how it works within your project so that you are capable of customizing the functionality later.

- [SnapshotsConcern](./lib/active_snapshot/models/concerns/snapshots_concern.rb)
  * Defines `snapshots` and `snapshot_items` has_many associations
  * Defines `create_snapshot!` and `has_snapshot_children` methods
- [Snapshot](./lib/active_snapshot/models/snapshot.rb)
  * Contains a unique `identifier` column (optional, but available for custom identification purposes)
  * `has_many :item_snapshots`
- [SnapshotItem](./lib/active_snapshot/models/snapshot_item.rb)
  * Contains `object` column which contains an encoded database row
  * `belongs_to :snapshot`


# Credits

Created & Maintained by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)
