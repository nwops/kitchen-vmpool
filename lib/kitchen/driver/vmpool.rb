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
        member = store.take_pool_member(config[:pool_name])
        info("Pool member #{member} was selected")
        state[:hostname] = member
      end

      # (see Base#destroy)
      def destroy(state)
        return unless state[:hostname]

        opts = {
            pool_member: state[:hostname],
            pool_name: config[:pool_name],
            reuse_instances: config[:reuse_instances],
        }

        store.cleanup(**opts) do |host, used_status|
          info("Marking pool member #{host} as #{used_status}")
        end

        state.delete(:hostname)
      end

      private

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

