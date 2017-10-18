require "kitchen/driver/vmpool_stores/base_store"
require 'kitchen/logging'

module Kitchen
  module Driver
    class PoolMemberNotFound < Exception; end

    module VmpoolStores
      class FileBaseStore < BaseStore
        attr_reader :pool_file, :pool_data
        include Kitchen::Logging

        # @return [String] - a random host from the list of systems
        # mark them used so nobody else can use it
        def take_pool_member(pool_name)
          member = pool_hosts(pool_name).sample
          raise Kitchen::Driver::PoolMemberNotFound.new("No pool members exist for #{pool_name}, please create some pool members") unless member
          mark_used(member, pool_name)
          member
        end

        # @param pool_member [String] a VM instance
        # @param pool_name [String] a VM pool
        # @param reuse_instances [Boolean] whether or not to mark used VM instances as unused
        def cleanup(pool_member:, pool_name:, reuse_instances:)
          used_status = 'garbage'
          if reuse_instances
            mark_unused(pool_member, pool_name)
            used_status = 'unused'
          else
            used_hosts(pool_name).delete(pool_member)
            add_to_garbage(pool_member, pool_name)
          end
          yield(pool_member, used_status) if block_given?
        end

        def pool_data(refresh = false)
          @pool_data = nil if refresh
          @pool_data ||= YAML.load(read_content)
        end

        def update(content = nil)
          write_content(content)
          read
        end

        def create
          write_content(base_content)
          read
        end

        def read
          read_content
        end

        def reread
          pool_data(true)
        end

        def save
          write_content
          read
        end

        private

        # @param pool_member [String]
        # @return Array[String] - list of instances in the garbage
        def add_to_garbage(pool_member, pool_name)
          return if garbage_hosts(pool_name).include?(pool_member)
          garbage_hosts(pool_name) << pool_member
          save
          garbage_hosts(pool_name)
        end

        # @param name [String] - the hostname to mark used
        # @return Array[String] - list of used instances
        def mark_used(name, pool_name)
          # ideally the member should not already be in this array
          # but just in case we will protect against that
          pool_hosts(pool_name).delete(name)
          used_hosts(pool_name) << name unless used_hosts(pool_name).include?(name)
          save
          used_hosts(pool_name)
        end

        # @param name [String] - the hostname to mark not used
        # @return Array[String] - list of unused instances
        def mark_unused(name, pool_name)
          used_hosts(pool_name).delete(name)
          pool_hosts(pool_name) << name unless pool_hosts(pool_name).include?(name)
          save
          pool_hosts(pool_name)
        end

        # @return Array[String] - a list of pool names
        def pool_names
          pool_data.keys
        end

        # @return [Hash] - a pool hash by the given pool_name from the config
        def pool(name)
          raise ArgumentError.new("Pool #{name} does not exist") unless pool_exists?(name)
          pool_data[name]
        end

        # @return [Boolean] - true if the pool exists
        def pool_exists?(name)
          pool_names.include?(name)
        end

        # @return Array[String] - a list of host names in the pool
        def pool_hosts(pool_name)
          pool(pool_name)['pool_instances'] ||= []
        end

        def garbage_hosts(pool_name)
          pool(pool_name)['garbage_collection'] ||= []
        end

        # @return Array[String] - a list of used host names in the pool
        def used_hosts(pool_name)
          pool(pool_name)['used_instances'] ||= []
        end

        def read_content
          raise NotImplementedError
        end

        def write_content(content = pool_data)
          raise NotImplementedError
        end
      end
    end
  end
end
