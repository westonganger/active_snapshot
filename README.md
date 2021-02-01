# ActiveSnapshot

<a href="https://badge.fury.io/rb/active_snapshot" target="_blank"><img height="21" style='border:0px;height:21px;' border='0' src="https://badge.fury.io/rb/active_snapshot.svg" alt="Gem Version"></a>
<img src="https://github.com/westonganger/active_snapshot/workflows/Tests/badge.svg" style="max-width:100%;" height='21' style='border:0px;height:21px;' border='0' alt="CI Status">
<a href='https://rubygems.org/gems/active_snapshot' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://ruby-gem-downloads-badge.herokuapp.com/active_snapshot?label=rubygems&type=total&total_label=downloads&color=brightgreen' border='0' alt='RubyGems Downloads' /></a>

Simplified snapshots and restoration for ActiveRecord models and associations with a transparent white-box implementation.

Key Features:

- Create and Restore snapshots of a parent record and any specified child records
- Predictible and explicit behaviour provides much needed clarity to your restore logic
- Snapshots are created upon request only, we do not use any callbacks
- Tiny method footprint so its easy to completely override the logic later

Why This Library:

Model Versioning and Restoration require concious thought, design, and understanding. You should understand your versioning and restoration process completely. This gem's small API and fully understandable design fully supports this.

I do not recommend using paper_trail-association_tracking because it is mostly a blackbox solution which encourages you to set it up and then assume its "Just working<sup>TM</sup>". This makes for major data problems later. Dont fall into this trap. Instead read this gems brief source code completely before use OR copy the code straight into your codebase. Once you know it, then you are free.



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
  include ActiveSortOrder
end
```

This defines the following associations on your models:

```ruby
has_many :snapshots, as: :item, class_name: 'Snapshot'
has_many :snapshot_items, as: :item, class_name: 'SnapshotItem'
```

It defines an optional extension to your model `has_snapshot_children`.

It defines one instance method to your model: `create_snapshot!`

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

```ruby
class Post < ActiveRecord::Base
  include ActiveSnapshot
  
  has_snapshot_children do
    ### Executed in the context of the instance / self

    ### In this example, we choose to do a fresh load from the database of the record and all associated records from the database
    instance = self.class.includes(:comments, :ip_address).find(id)
    
    ### Define the associated records that will be restored
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

```ruby
reified_items = snapshot.fetch_reified_items
```

As a safety these records have the `@readonly = true` attribute set on them. If you want to perform any write actions on the returned instances you will have to set `@readonly = nil`.

```ruby
writable_reified_items = snapshot.fetch_reified_items.transform_values do |array| 
  array.map{|x| x.instance_variable_set("@readonly", false); x}
end
```

# Key Models Provided & Additional Customizations

A key aspect of this library is its simplicity and small API. For major functionality customizations we encourage you to first delete this gem and then copy this gems code directly into your repository.

I strongly encourage you to read the code for this library to understand how it works within your project so that you are capable of customizing the functionality later.

- [SnapshotsConcern](./lib/active_snapshot/snapshots_concern.rb)
  * Defines `snapshots` and `snapshot_items` has_many associations
  * Defines `create_snapshot!` and `has_snapshot_children` methods
- [Snapshot](./lib/active_snapshot/snapshot.rb)
  * Contains a unique `identifier` column
  * `has_many :item_snapshots`
- [SnapshotItem](./lib/active_snapshot/snapshot_item.rb)
  * Contains `object` column with yaml encoded model instance `attributes`
  * `belongs_to :snapshot`


# Credits

Created & Maintained by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)
