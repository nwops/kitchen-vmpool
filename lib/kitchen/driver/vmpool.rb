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
require 'kitchen/logging'
require 'kitchen/driver/base'
require 'kitchen-vmpool/version'

module Kitchen
  module Driver

    class PoolMemberNotFound < Exception; end

    class Vmpool < Kitchen::Driver::Base
      include Kitchen::Logging

      plugin_version KitchenVmpool::VERSION

      default_config :pool_name, 'pool1'
      default_config :state_store, 'file'
      default_config :store_options, {}
      default_config :reuse_instances, false
      default_config :create_command, nil
      default_config :destroy_command, nil

      no_parallel_for :create, :destroy

      # (see Base#create)
      def create(state)
        state[:hostname] = take_pool_member
      end

      # (see Base#destroy)
      def destroy(state)
        return if state[:hostname].nil?
        mark_unused(state[:hostname])
        state.delete(:hostname)
      end

      private

      # @return [String] - a random host from the list of systems
      # mark them used so nobody else can use it
      def take_pool_member
        member = pool_hosts.sample
        raise PoolMemberNotFound.new("No pool members exist for #{config[:pool_name]}, please create some pool members") unless member
        mark_used(member)
        info("Pool member #{member} was selected")
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
        pool['pool_instances'] ||= []
      end

      # @return Array[String] - a list of used host names in the pool
      def used_hosts
        pool['used_instances'] ||= []
      end

      # @param name [String] - the hostname to mark not used
      # @return Array[String] - list of unused instances
      def mark_unused(name)
        if config[:reuse_instances]
          info("Marking pool member #{name} as unused")
          used_hosts.delete(name)
          pool_hosts << name unless pool_hosts.include?(name)
        end
        store.save
        pool_hosts
      end

      # @param name [String] - the hostname to mark used
      # @return Array[String] - list of used instances
      def mark_used(name)
        debug("Marking pool member #{name} as used")
        # ideally the member should not already be in this array
        # but just in case we will protect against that
        pool_hosts.delete(name)
        used_hosts << name unless used_hosts.include?(name)
        store.save
        used_hosts
      end

      # @return [Hash] - a store hash that contains one or more pools
      def store
        @store ||= begin
          # load the store adapter and create a new instance of the store
          name = config[:state_store].split('_').map(&:capitalize).join('')
          store = sprintf("%s%s", name, 'Store')
          store_file = "#{config[:state_store]}_store"
          require "kitchen/driver/vmpool_stores/#{store_file}"
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

require 'gitlab'
# monkey patch error in error code until it is fixed upstream
module Gitlab
  module Error
    class ResponseError
      # Human friendly message.
      #
      # @return [String]
      private
      def build_error_message
        parsed_response = @response.parsed_response
        message = parsed_response.respond_to?(:message) ? parsed_response.message : parsed_response['message']
        message = parsed_response.error unless message
        "Server responded with code #{@response.code}, message: " \
        "#{handle_message(message)}. " \
        "Request URI: #{@response.request.base_uri}#{@response.request.path}"
      end
    end
  end
end
