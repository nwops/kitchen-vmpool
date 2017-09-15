require 'yaml'
require 'kitchen'

module Kitchen
  module Driver
    class PoolMemberNotFound < Exception; end
    class PoolNotFound < Exception; end
    class PoolIsEmpty < Exception; end
    class PoolMemberUnavailable < Exception; end
    class TokenNotCreated < Exception; end
    class AuthenticationRequired < Exception; end
    class InvalidCredentials < Exception; end
    class PoolMemberNotDestroyed < Exception; end
    class InvalidUrl < Exception; end

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

        # @param pool_member [String] - the name of the VM
        # @param pool_name [String] - the name of the pool
        # @param reuse_instances [Boolean] - whether or not the VM should be discarded when used
        # a callback that executes when a pool member has been run
        def cleanup(pool_member: nil, pool_name: nil, reuse_instances: false, &block)
          raise NotImplemented
        end
      end
    end
  end
end
