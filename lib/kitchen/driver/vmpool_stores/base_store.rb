require 'yaml'
require 'kitchen/logger'
require 'kitchen'
require 'kitchen/logging'

module Kitchen
  module Driver
    module VmpoolStores
      class BaseStore
        attr_reader :pool_file, :pool_data
        include Kitchen::Logging

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

        def pool_data(refresh = false)
          @pool_data = nil if refresh
          @pool_data ||= YAML.load(read_content)
        end

        private

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
