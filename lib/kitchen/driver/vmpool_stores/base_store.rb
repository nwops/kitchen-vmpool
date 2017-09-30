require 'yaml'
require 'kitchen'

module Kitchen
  module Driver
    class PoolMemberNotFound < Exception; end

    module VmpoolStores
      class BaseStore

        def initialize(options = {})
          
        end

        # @return [String] - a random host from the list of systems
        # mark them used so nobody else can use it
        # @param pool_name [String] - the name of the pool to yank the memeber from
        def take_pool_member(pool_name)
          raise NotImplemented
        end

        # @param name [String] - the hostname to mark not used
        # @param pool_name [String] - the name of the pool to yank the memeber from
        # @return Array[String] - list of unused instances
        def mark_unused(name, pool_name, reuse = false)
          raise NotImplemented
        end
      end
    end
  end
end
