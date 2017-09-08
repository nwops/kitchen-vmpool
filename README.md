# Kitchen::Vmpool

Ever wished you didn't have to wait for test-kitchen to create a test node?  With kitchen-vmpool you can create your test nodes
ahead of time and simply populate the pool with the list of hostnames.  During the create step test kitchen will select a member
of the test pool and you will instantly have a system to work with.

Kitchen-vmpool allows external scripts or programs to populate the pool so it is not tied to any single vm/container technology.
Additionaly, kitchen-vmpool contains a pluggable storage backend so that you can store the pool information in just about anything. 

## Installation


```ruby
gem 'kitchen-vmpool'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kitchen-vmpool

## Usage

To use setup the kitchen driver to use the vmpool store and configure one of the stores if required. 

### Gitlab Commit Store Example
If you have no central place to store files the gitlab_commit store may be an option for you.
If you have a simple setup thus may suffice.  If you plan to expand your usage of test kitchen to 
include multiple parallel test runs, you may run into race conditions due to the lack of a central queue
to handle reads and writes.  Perfect for simple setups.  Later on you can move to a different state store.

```yaml
driver:
  name: vmpool
  reuse_instances: false
  state_store: gitlab_commit
  store_options:
    pool_file: 'vmpool'
    project_id: 329302
    
platforms:
    - name: rhel6
      driver:
        pool_name: base_rhel6_pool
    - name: windows10
      driver:
        pool_name: windows10_pool  
    
```

### Gitlab Snippet Store Example
I don't recommend using the snippet store because gitlab's permission's model only allows a single
user to make changes.  Therefore this is a bad central place to keep things if only a single user can update.
Use this as an example to create your own store providers.

```yaml
driver:
  name: vmpool
  reuse_instances: false
  state_store: gitlab_snippet
  store_options:
    pool_file: 'vmpool'
    project_id: 329302
    snippet_id: 49
    
platforms:
    - name: rhel6
      driver:
        pool_name: base_rhel6_pool
    - name: windows10
      driver:
        pool_name: windows10_pool    
```

### Plain old file store
Probably the easiest to setup, but is useful only for a single person on the same system.

```yaml
driver:
  name: vmpool
  reuse_instances: false
  state_store: file
  store_options:
    pool_file: 'vmpool'
    
platforms:
    - name: rhel6
      driver:
        pool_name: base_rhel6_pool
    - name: windows10
      driver:
        pool_name: windows10_pool      
```

### Pool data structure
The basic structure of the pool data can be found below.  This is the current format that each state store will follow. 

```yaml
base_rhel6_pool:
  payload_file: base_rhel6_payload.json
  size: 1
  pool_instances: []
  requests: []
  used_instances: []
  
windows10_pool:
  payload_file: windows10_payload.json
  size: 1
  pool_instances: []
  requests: []
  used_instances: []
     
```

The payload_file key is not required and was used for other purposes outside of kitchen-vmpool in order to create the instances.
It can be expected that some users will throw extra metadata in these pools for their own purposes.  So care must be
taken to not wipe out this data when creating a store.

### Puppet's VMpooler
Consider the VMpooler state store to be the ultimate backend for kitchen-vmpool.  While vmpool doesn't currently support vmpooler
it is on the roadmap to support. 

https://github.com/puppetlabs/vmpooler

Once the vmpooler state store is implemented this kitchen plugin might be pretty popular.

## Development

This plugin was intended to support multiple ways to populate the pool and multiple ways to store the state of those pools.
Therefore we leave it up to the user to create the pool instances while kitchen's job is only to interface with the pool information.
Pool members need to be created outside of kitchen-vmpool.  Additionally pool member information must also be updated outside of kitchen-vmpool.

Puppet's vmpooler will handle the maintenance of the pool state which is probably what you want.


### Creating a State Store

In order to create a new state store you must do the following:

1. inherit from the BaseStore or a subclass of the BaseStore
2. Implement the following methods:
    * initialize(options = {}) 
    * take_pool_member
    * mark_unused
    
4. All other methods used with your store must be private 

You must be careful to overwrite the entire pool data.  It is expected that some users
will put other metadata in the pool file for other purposes.  So when you write your data
please ensure you merge with the previous data first.

Example:

```ruby
module Kitchen
  module Driver
    module VmpoolStores
      class FileBaseStore < BaseStore
        # @return [String] - a random host from the list of systems
        # mark them used so nobody else can use it
        def take_pool_member(pool_name)
          member = pool_hosts(pool_name).sample
          raise Kitchen::Driver::PoolMemberNotFound.new("No pool members exist for #{pool_name}, please create some pool members") unless member
          mark_used(member, pool_name)
          return member
        end

        # @param name [String] - the hostname to mark not used
        # @return Array[String] - list of unused instances
        def mark_unused(name, pool_name, reuse = false)
          if reuse
            used_hosts(pool_name).delete(name)
            pool_hosts(pool_name) << name unless pool_hosts(pool_name).include?(name)
          end
          save
          pool_hosts(pool_name)
        end
      end
    end
  end    
end

```

### Adding Configuration for your store

You can pass configuration to your store by setting the `store_options` in the driver section.  This is a simple hash
that allows the user to pass in required settings if your store requires configuration.  It is up to you
use these options since not every store will require configuration.


### Development Setup
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/logicminds/kitchen-vmpool. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Kitchen::Vmpool project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/logicminds/kitchen-vmpool/blob/master/CODE_OF_CONDUCT.md).
