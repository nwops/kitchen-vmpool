require "kitchen/driver/vmpool_stores/file_base_store"
require 'kitchen/logging'

module Kitchen
  module Driver
    module VmpoolStores
      class FileStore < FileBaseStore
        include Kitchen::Logging

        # @option pool_file [String] - the file path that holds the pool information
        def initialize(options = nil)
          raise ArgumentError unless options['pool_file']
          options ||= { 'pool_file' => 'vmpool.yaml' }
          @pool_file = options['pool_file']
        end

        private

        def base_content
          {
            pool1: {
              size: 1,
              pool_instances: [],
              used_instances: [],
              requests: []
            }
          }
        end

        def read_content
          data = File.read(pool_file)
          raise ArgumentError unless data
          data
        end

        def write_content(content = pool_data)
          File.open(pool_file, 'w') { |f| f.write(content.to_yaml) }
        end

      end
    end
  end
end
