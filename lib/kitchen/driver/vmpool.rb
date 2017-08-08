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
require "kitchen/vmpool/version"
require "kitchen"
require "kitchen/version"

module Kitchen
  module Driver
    class Vmpool < Kitchen::Driver::SSHBase
      plugin_version Kitchen::Vmpool::VERSION

      required_config :pool_name
      required_config :pool_file
      required_config :create_command
      default_config :destroy_command
      default_config :state_store

      no_parallel_for :create, :destroy

      # (see Base#create)
      def create(state)
        state[:hostname] = config[:host]
        reset_instance(state)
      end

      # (see Base#destroy)
      def destroy(state)
        return if state[:hostname].nil?
        reset_instance(state)
        state.delete(:hostname)
      end
    end
  end
end
