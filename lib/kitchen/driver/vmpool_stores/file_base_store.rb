require "kitchen/driver/vmpool_stores/base_store"

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

        def pool_data(refresh = false)
          @pool_data = nil if refresh
          @pool_data ||= YAML.load(read_content)
        end

        private

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

        # @return Array[String] - a list of used host names in the pool
        def used_hosts(pool_name)
          pool(pool_name)['used_instances'] ||= []
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

        def update(content = nil)
          #info("Updating vmpool data")
          write_content(content)
          read
        end

        def create
          #info("Creating new vmpool data")
          write_content(base_content)
          read
        end

        def read
          #info("Reading vmpool data")
          read_content
        end

        def reread
          pool_data(true)
        end

        def save
          #info("Saving vmpool data")
          write_content
          read
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
