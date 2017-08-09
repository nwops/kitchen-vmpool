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
require "kitchen"
require "kitchen/version"

module Kitchen
  module Driver
    class Vmpool < Kitchen::Driver::SSHBase
      plugin_version "0.1.0"

      default_config :pool_name, 'pool1'
      default_config :pool_file, 'vmpool.yaml'
      default_config :state_store, 'file'
      default_config :store_options, {}

      required_config :create_command
      default_config :destroy_command, nil

      no_parallel_for :create, :destroy

      # (see Base#create)
      def create(state)
        state[:hostname] = pool_member(config[:pool_name])
        reset_instance(state)
      end

      # (see Base#destroy)
      def destroy(state)
        return if state[:hostname].nil?
        reset_instance(state)
        state.delete(:hostname)
      end

      private

      def pool_member(pool_name)
        pool_hosts
      end

      def pool_names
        store.pool_data.keys
      end

      def pool
        store[config[:pool_name]]
      end

      def pool_hosts
        pool['instances']
      end

      def store
        @store ||= begin
          store = sprintf("%s%s", config[:state_store].capitalize, 'Store')
          require "kitchen/driver/vmpool_stores/#{config[:state_store]}_store"
          klass = Object.const_get("Kitchen::Driver::VmpoolStores::#{store}")
          klass.send(:new, config[:store_options])
        end
      end

    end
  end
end
