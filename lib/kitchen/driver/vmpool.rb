# -*- encoding: utf-8 -*-
#
# Author:: Corey Osman <corey@nwops.io>
#
# Copyright:: Copyright (c) 2017 NWOPS, LLC.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'kitchen'
require "kitchen/version"
require 'kitchen/driver/base'
module Kitchen
  module Driver

    class PoolMemberNotFound < Exception; end

    class Vmpool < Kitchen::Driver::Base
      plugin_version "0.1.1"

      default_config :pool_name, 'pool1'
      default_config :pool_file, 'vmpool.yaml'
      default_config :state_store, 'file'
      default_config :store_options, {}
      default_config :reuse_instances, false
      default_config :create_command, nil
      default_config :destroy_command, nil

      no_parallel_for :create, :destroy

      # (see Base#create)
      def create(state)
        state[:hostname] = pool_member
      end

      # (see Base#destroy)
      def destroy(state)
        return if state[:hostname].nil?
        mark_unused(state[:hostname])
        state.delete(:hostname)
      end

      private

      # @return [String] - a random host from the list of systems
      def pool_member
        sample = pool_hosts.sample
        raise PoolMemberNotFound.new("No pool members exist for #{config[:pool_name]}, please create some pool members") unless sample
        member = pool_hosts.delete(sample)
        mark_used(member)
        return member
      end

      # @return Array[String] - a list of pool names
      def pool_names
        store.pool_data.keys
      end

      # @return [Hash] - a pool hash by the given pool_name from the config
      def pool
        name = config[:pool_name]
        raise ArgumentError.new("Pool #{name} does not exist") unless pool_exists?(name)
        store.pool_data[name]
      end

      # @return [Boolean] - true if the pool exists
      def pool_exists?(name)
        pool_names.include?(name)
      end

      # @return Array[String] - a list of host names in the pool
      def pool_hosts
        if config[:reuse_instances]
          (pool['pool_instances'] + pool['used_instances'].to_a).uniq
        else
          pool['pool_instances']
        end
      end

      # @param name [String] - the hostname to mark not used
      # @return Array[String] - list of unused instances
      def mark_unused(name)
        pool['pool_instances'] = [] unless pool['pool_instances']
        pool['pool_instances'] << name
        store.save
        pool['pool_instances']
      end

      # @param name [String] - the hostname to mark used
      # @return Array[String] - list of used instances
      def mark_used(name)
        pool['used_instances'] = [] unless pool['used_instances']
        pool['used_instances'] << name
        store.save
        pool['used_instances']
      end

      # @return [Hash] - a store hash that contains one or more pools
      def store
        @store ||= begin
          # load the store adapter and create a new instance of the store
          store = sprintf("%s%s", config[:state_store].capitalize, 'Store')
          require "kitchen/driver/vmpool_stores/#{config[:state_store]}_store"
          klass = Object.const_get("Kitchen::Driver::VmpoolStores::#{store}")
          # create a new instance of the store with the provided options
          store_opts = config[:store_options]
          # convert everything key to strings
          store_opts.tap do |h|
            h.keys.each { |k| h[k.to_s] = h.delete(k) }
          end
          klass.send(:new, store_opts)
        end
      end

    end
  end
end
