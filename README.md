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

Now all models inheriting from ActiveRecord::Base have the following associations defined on them:

```ruby
has_many :snapshots, as: :item, class_name: 'Snapshot'
has_many :snapshot_items, as: :item, class_name: 'SnapshotItem'
```

# Usage

First, you must define the following instance methods on each model you want to snapshot. These are just examples to give you an idea.

```ruby
class Post < ActiveRecord::Base
  has_many :comments
  has_one :ip_address

  def children_to_snapshot
    association_names = [
      "comments",
      "ip_address",
    ]

    ### We load the current record and all associated records fresh from the database
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

  def snapshot_child_delete_item_function(child_record)
    if ['TimeSlot', 'IpAddress'].include?(child_record.class.name)
      ### In this example, we dont want to delete these because they
      ### are not independent child records to the parent model so we just "release" them
      item.release!
    else
      item.destroy!
    end
  end

end
```

Then you can use the following methods:

```ruby
post = Post.first

# Create snapshot grouped by identifier, user and metadata are optional
snapshot = post.create_snapshot!("snapshot_1", user: current_user, metadata: {foo: :bar})

# Restore snapshot and all its child snapshots
snapshot.restore!

# Destroy snapshot and all its child snapshots
# must be performed manually, snapshots and snapshot items are NEVER destroyed automatically
snapshot.destroy!

# Add additional records to snapshot, know what your doing before manually calling this
snapshot.create_snapshot_item!(another_child_record)
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
