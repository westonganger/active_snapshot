# ActiveSnapshot

<a href="https://badge.fury.io/rb/active_snapshot" target="_blank"><img height="21" style='border:0px;height:21px;' border='0' src="https://badge.fury.io/rb/active_snapshot.svg" alt="Gem Version"></a>
<a href='https://travis-ci.com/westonganger/active_snapshot' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://api.travis-ci.org/westonganger/active_snapshot.svg?branch=master' border='0' alt='Build Status' /></a>
<a href='https://rubygems.org/gems/active_snapshot' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://ruby-gem-downloads-badge.herokuapp.com/active_snapshot?label=rubygems&type=total&total_label=downloads&color=brightgreen' border='0' alt='RubyGems Downloads' /></a>

Simplified snapshots and restoration for ActiveRecord models and associations with a transparent white-box implementation.

⚠️  **Warning: v0.x releases are subject to API changes**

Key Features:

- Create and Restore snapshots of a parent record and any specified child records
- Predictible and explicit behaviour provides much needed clarity to your restore logic
- Snapshots are created upon request only, we do not use any callbacks
- Tiny method footprint so its easy to completely override the logic later

Why This Library:

Model Versioning and Restoration require concious thought, design, and understanding. You should understand your versioning and restoration process completely. Our small API and simple design supports this. If you are considering using [paper_trail-association_tracking](https://github.com/westonganger/paper_trail-association_tracking) then you should think again because PT-AT is mostly a blackbox solution which encourages you to set it up and then assume its "just working". This makes for major data problems later.


# Installation

```ruby
gem 'active_snapshot'
```

Then generate and run the necessary migrations to setup the `snapshots` and `snapshot_items` tables.

```
rails generate active_snapshot:install
rake db:migrate
```

It will also include the `SnapshotsConcern` to your ApplicationRecord or create an initializer if the ApplicationRecord model doesnt exist.

```ruby
# config/initializers/active_snapshot.rb

### Load for all ActiveRecord models
ActiveSupport.on_load(:active_record) do
  include SnapshotsConcern
end
```

Now all models inheriting from ActiveRecord::Base have the `SnapshotsConcern` applied which defines the following associations on your models:

```ruby
has_many :snapshots, as: :item, class_name: 'Snapshot'
has_many :snapshot_items, as: :item, class_name: 'SnapshotItem'
```

It defines an optional extension to your models `has_snapshot_children`.

It defines one instance method to your models: `create_snapshot!`

# Basic Usage

You now have access to the following methods:

```ruby
post = Post.first

# Create snapshot grouped by identifier, only :identifier argument is required, all others are optional
snapshot = post.create_snapshot!(
  identifier: "snapshot_1", # Required
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

# Restoring Associated / Child Records

In the following example the values within the `:children` argument refer to an instance method that is defined on your model (`post` in this case).

```ruby
class Post
  
  has_snapshot_children do
    ### Executed in the context of the instance / self

    ### In this example we just load the current record and all associated records fresh from the database
    instance = self.class.includes(:comments, :ip_address).find(id)
    
    {
      comments: instance.comments,
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

Warning: If you call any save action on these items it will overwrite the actual record.

```ruby
reified_items = snapshot.fetch_reified_items
```

# Key Models Provided
- [Snapshot](https://github.com/westonganger/active_snapshot/blob/master/lib/active_snapshot/snapshot.rb)
  * Contains a unique `identifier` column
  * `has_many :item_snapshots`
- [SnapshotItem](https://github.com/westonganger/active_snapshot/blob/master/lib/active_snapshot/snapshot_item.rb)
  * Contains `object` column with yaml encoded model instance `attributes`
  * `belongs_to :snapshot`
- [SnapshotsConcern](https://github.com/westonganger/active_snapshot/blob/master/lib/active_snapshot/snapshots_concern.rb)
  * Defines `snapshots` and `snapshot_items` has_many associations
  * Defines `create_snapshot!` and `has_snapshot_children` methods

# Additional Customizations

A key aspect of this library is its simplicity and small API. For major functionality customizations we encourage you to first delete this gem and then copy this gems code directly into your repository.

I strongly encourage you to read the code for this library to understand how it works within your project so that you are capable of customizing the functionality later.

# Credits

Created & Maintained by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)
