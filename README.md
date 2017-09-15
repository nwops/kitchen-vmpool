# Kitchen-Vmpool

Ever wished you didn't have to wait for test-kitchen to create a test node?  With kitchen-vmpool you can create your test nodes
ahead of time and simply populate the pool with the list of hostnames.  During the create step test kitchen will select a member
of the test pool and you will instantly have a system to work with.

Kitchen-vmpool allows external scripts or programs to populate the pool so it is not tied to any single vm/container technology.
Additionaly, kitchen-vmpool contains a pluggable storage backend so that you can store the pool information in just about anything.

Increase your perceived test kitchen host creation time by 200x!

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

## Intro
### Adding members to the pool
Kitchen-vmpool is agnostic to any vm/container technology.  This means you can use whatever provisioning mechanism you need to create a system or container.
However, it is expected that you will be provisioning hosts outside of your normal test-kitchen workflow.  
So all those cool fancy kitchen driver plugins cannot be used with vmpool.  But if you are reading this, that means your drivers take too long to spin up
an instance anyways.  So this means that you will need an external process that spins up instances.

In fact there is a tool that helps immensely with this already: [VMPooler](https://github.com/puppetlabs/vmpooler)

As I mentioned about you can use vmpooler or create a script to initially and constly generate your pool members.
Expect a scheduled/cron job to constant keep pool members in the pool.

An example working script I created for usage with VMware VRA can be found in the exe folder of this gem.  However, I will
later be transitioning to [VMPooler](https://github.com/puppetlabs/vmpooler).

### State Stores
When we are working with vmpools we need a way to store metadata about that pools and how many instances are required and currently available for each pool.  The easiest way to do this at first is to put that data in a file.
However, most people need things like central locking and management layers in front of that data.  So Kitchen-vmpool creates a framework for many other
state stores to be used.  Vmpool even allows the user to create their own state store and package as a separate gem.  
Test kitchen will use these state stores to get members of the pools in order to test against.

## Currently Available State stores

### Gitlab Commit Store Example
If you have no central place to store files the gitlab_commit store may be an option for you.
If you have a simple setup this may suffice.  If you plan to expand your usage of test kitchen to
include multiple parallel test runs, you may run into race conditions due to the lack of a central queue
to handle reads and writes.  Perfect for simple setups.  Later on you can move to a different state store.
Due to a gitlab bug I recommend naming your file without a file extension.

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
Use this as an example to create your own store providers.  This originally sounded like a good idea, but later turned out
to be bad idea due to the permissions model in Gitlab.

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

### Vmpooler store
Consider the Vmpooler state store to be the ultimate backend for kitchen-vmpool. You can now setup
[vmpooler](https://github.com/puppetlabs/vmpooler) to continuously regenerate virtual machines in the background.

```yaml
driver:
  name: vmpool
  state_store: vmpooler
  store_options:
    user: 'jdoe'
    pass: 'jdoe123'
    token: 'token'
    host_url: 'http://localhost:8080'
platforms:
    - name: rhel6
      driver:
        pool_name: base_rhel6_pool
    - name: windows10
      driver:
        pool_name: windows10_pool      
```

You will notice that the `reuse_instances` and `pool_file` options are not needed in this driver config. However,
we do need to supply some new options. Vmpooler store relies on an external service, so we need to provide an address
(`host_url`) and authentication credentials (`token` or `user` and `pass`).

### File based pool data structure
File based state stores require a file to store the data.  Duh!  In order to have
a common format between all the file based state stores you should use the data structure
below.  If you make your own state store you can do whatever you desire.  All state stores in this gem will use the
format below.

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

The `payload_file` key is not required and was used for other purposes outside of kitchen-vmpool in order to create the vra instances.
It can be expected that some users will throw extra metadata in these pools for their own purposes.  So care must be
taken to not wipe out this data when creating a new state store.


## Development

This plugin was intended to support multiple ways to populate the pool and multiple ways to store the state of those pools.
Therefore we leave it up to the user to create the pool instances while kitchen's job is only to interface with the pool information.
Pool members need to be created outside of kitchen-vmpool.  Additionally pool member information must also be updated outside of kitchen-vmpool.

Puppet's vmpooler will handle the maintenance of the pool state which is probably what you want.


### Creating a State Store

In order to create a new state store you must do the following:

1. Inherit from the BaseStore or a subclass of the BaseStore
2. Implement the following methods:
    * initialize(options = {})
    * take_pool_member
    * cleanup
    
3. All other methods used with your store must be private 

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
        
        # @param pool_member [String] a VM instance
        # @param pool_name [String] a VM pool
        # @param reuse_instances [Boolean] whether or not to mark used VM instances as unused
        def cleanup(pool_member:, pool_name:, reuse_instances:, &block)
          used_status = 'used'

          if reuse_instances
            mark_unused(pool_member, pool_name)
            used_status = 'unused'
          end

          block.call(pool_member, used_status)
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

### Custom State Store Distrubtion
If you think many will benefit from your new state store please create a PR and have it merged to the kithen-vmpool core.
We want to limit dependencies so if your fancy state store has some dependencies it would probably be best to create your own gem.

It is easiest to create a gem using bundler.  Please use the naming convention kitchen-vmpool-storename when creating your gem.

1. `bundler gem --test=rspec kitchen-vmpool-fancystore`
2. Create a kitchen/driver directory
3. Move the vmpool directory underneath kitchen/driver directory
4. rename vmpool directory to vmpool_stores
```
lib
└── kitchen
    └── driver
        └── vmpool_stores
            ├── fancystore
            │   └── version.rb
            └── fancystore.rb --> your code goes in this file

```

There is much more to bundling this into a gem but the procedures are the same for every gem.  So add gem dependencies if required
and be sure to add unit tests for your state store.

### Development Setup
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## VMware VRA Pool creation scripts
I had a need to interface kitchen-vmpool with VRA in order to build catalog items.  So I ended up creating some basic scripts that utilize the [vmware-vra gem](https://github.com/chef-partners/vmware-vra-gem)
to help build the catalog items.  I am also using the gitlab_commit store as my storage backend.  Don't ask why it is all I had.

Warning: this code is very custom for my own needs and utilizes the gitlab_commit store for state storage.  

### Usage

Gems required:
 - hashdiff
 - vmware-vra
 - gitlab
 - highline

Help: `vra_create_pool -h`
Create a pool: `vra_create_pool -f vmpool -p 1234`

Requires the basic file based vmpool file

```yaml
base_rhel6_pool:
  payload_file: base_rhel6_payload.json
  size: 1
  pool_instances: []
  requests: []
  used_instances: []

```

I have some PRs open to help make using VRA payloads files easier with vmware-vra.

See:
  - https://github.com/chef-partners/vmware-vra-gem/pull/57
  - https://github.com/chef-partners/vmware-vra-gem/pull/56

You should be able to easily swap out the store for something else too.  Just edit the vra_create_pool file here.

```ruby
# @return [Hash] - a store hash that contains one or more pools
# @option project_id [Integer] - the project id in gitlab
# @option pool_file [String] - the snipppet file name
def store(store_options = options)
  # create a new instance of the store with the provided options
  @store ||= Kitchen::Driver::VmpoolStores::GitlabCommitStore.new(store_options)
end

```
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nwops/kitchen-vmpool. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Kitchen::Vmpool project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/logicminds/kitchen-vmpool/blob/master/CODE_OF_CONDUCT.md).
