# ActiveSnapshot

<a href="https://badge.fury.io/rb/active_snapshot" target="_blank"><img height="21" style='border:0px;height:21px;' border='0' src="https://badge.fury.io/rb/active_snapshot.svg" alt="Gem Version"></a>
<a href='https://travis-ci.com/westonganger/active_snapshot' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://api.travis-ci.org/westonganger/active_snapshot.svg?branch=master' border='0' alt='Build Status' /></a>
<a href='https://rubygems.org/gems/active_snapshot' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://ruby-gem-downloads-badge.herokuapp.com/active_snapshot?label=rubygems&type=total&total_label=downloads&color=brightgreen' border='0' alt='RubyGems Downloads' /></a>

Dead simple snapshot versioning for ActiveRecord models and associations. I created this as a transparent white-box alternative to the gems paper_trail and paper_trail-association_tracking.

⚠️  **Warning: v0.x releases are subject to API changes**

Key Features:

- Create and Restore snapshots of a parent record and any specified child records
- Snapshots are created upon request only, we do not use Activerecord callbacks
- Predictible and explicit behaviour provides much needed clarity to your restore logic
- Tiny method footprint so its easy to completely override the logic later

Why This Library:

- Model Versioning and Restoration require concious thought, design, and understanding.
- You should understand the versioning and restoration process completely. Our small API and simple design supports this.
- If your considering using [paper_trail-association_tracking](https://github.com/westonganger/paper_trail-association_tracking) then you should re-consider because:
  * PT-AT is mostly a blackbox solution that you likely do not fully understand
  * PT-AT encourages you to set it up and then assume its "just working". This makes for major data problems later.

Notice: I strongly encourage you to read the code for this library to understand how it works within your project so that you are capable of customizing the functionality later.

# Installation

```ruby
gem 'active_snapshot'
```

Then generate and run the necessary migrations to setup the `snapshots` and `snapshot_items` tables.

```
rails generate active_snapshot:install
rake db:migrate
```

There will also be an initializer that applies the SnapshotsConcern to your models

```ruby
if defined?(ApplicationRecord)
  ApplicationRecord.class_eval do
    include SnapshotsConcern
  end
else
  ### Load for all ActiveRecord models
  ActiveSupport.on_load(:active_record) do
    include SnapshotsConcern
  end
end
```

Now all models inheriting from ActiveRecord::Base have the `SnapshotsConcern` applied which defines the following associations on your models:

```ruby
has_many :snapshots, as: :item, class_name: 'Snapshot'
```

It only defines one additional instance method to your models: `create_snapshot!`

# Usage

You now have access to the following methods:

```ruby
post = Post.first

# Create snapshot grouped by identifier, only :identifier argument is required, all others are optional
snapshot = post.create_snapshot!(
  identifier: "snapshot_1", # Required
  user: current_user,
  children: {
    records:  :children_to_snapshot,
    restore_allowed: :snapshot_restore_allowed?,
    delete_item_function: :snapshot_child_delete_item_function,
  },
  metadata: {
    foo: :bar
  },
)

# Restore snapshot and all its child snapshots
if snapshot.restore!
  puts "Success"
else
  puts "Restore Not Allowed"

# Destroy snapshot and all its child snapshots
# must be performed manually, snapshots and snapshot items are NEVER destroyed automatically
snapshot.destroy!
```

# Restoring Associated / Child Records

In the following example the values within the `:children` argument refer to an instance method that is defined on your model (`post` in this case).

```ruby
snapshot = post.create_snapshot!(
  identifier: "snapshot_1", # Required
  children: {
    records:  :children_to_snapshot,
    restore_allowed: :snapshot_restore_allowed?,
    delete_strategy: :snapshot_delete_strategy,
  },
)
```

You can also use procs instead if you dont want to define the instance methods.

```ruby
restore_allowed = ->(post) do
  # Custom logic here, has access to the post that `create_snapshot` was called from
end

snapshot = post.create_snapshot!(
  identifier: "snapshot_1", # Required
  children: {
    restore_allowed: restore_allowed,
```

Here are some method examples to give you an idea.

```ruby
class Post < ActiveRecord::Base
  has_many :comments
  has_one :ip_address

  def children_to_snapshot
    association_names = [
      "comments",
      "ip_address",
    ]

    ### In this example we just load the current record and all associated records fresh from the database
    instance = self.class.includes(*association_names).find(id)

    child_items = []

    association_names.each do |assoc_name|
      child_items << instance.send(assoc_name)
    end

    ### Flatten the child_items array
    ### Note: has_many associations return an ActiveRecord::Associations::CollectionProxy
    ### so we must call `to_a` on them
    child_items = child_items.flat_map{|x| x.respond_to?(:to_a) ? x.to_a : x}

    ### Remove any empty items
    child_items.compact

    return child_items
  end

  def snapshot_restore_allowed?
    # TODO
  end

  def snapshot_item_delete_strategy(snapshot_items)
    children_to_keep = Set.new

    snapshot_items.each do |snapshot_item|
      key = "#{snapshot_item.item_type} #{snapshot_item.item_id}"
      children_to_keep << key
    end

    ### Destroy or Detach Items not included in this Snapshot's Items
    ### We do this first in case you decide to validate children in ItemSnapshot#restore_item! method
    children_to_snapshot.each do |child_record|
      key = "#{child_record.class.name} #{child_record.id}"

      if !children_to_keep.include?(key)
        if ['TimeSlot', 'IpAddress'].include?(child_record.class.name)
          ### In this example, we dont want to delete these because they
          ### are not independent child records to the parent model so we just "release" them
          self.release!
        else
          item.destroy!
        end
      end
    end
  end

end
```

# Key Models Provided
- [Snapshot](https://github.com/westonganger/active_snapshot/blob/master/lib/active_snapshot/snapshot.rb)
  * Contains a unique `identifier` column
  * `has_many :item_snapshots`
- [SnapshotItem](https://github.com/westonganger/active_snapshot/blob/master/lib/active_snapshot/snapshot_item.rb)
  * Contains `object` column with yaml encoded model instance `attributes`
  * `belongs_to :snapshot`
- [SnapshotsConcern](https://github.com/westonganger/active_snapshot/blob/master/lib/active_snapshot/snapshots_concern.rb)
  * This concern is automatically applied to all ActiveRecord models
  * Defines `snapshots` and `snapshot_items` has_many associations
  * Defines `create_snapshot!` instance method

# Additional Customizations

A key aspect of this library is its simplicity and small API. For major functionality customizations we encourage you to first delete this gem and then copy this gems code directly into your repository.

I strongly encourage you to read the code for this library to understand how it works within your project so that you are capable of customizing the functionality later.

# Credits

Created & Maintained by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)
