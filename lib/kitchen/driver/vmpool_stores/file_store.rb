require 'yaml'

module Kitchen
  module Driver
    module VmpoolStores
      class FileStore

        attr_reader :pool_file

        # @option pool_file [String] - the file path that holds the pool information
        def initialize(options = nil)
          raise ArgumentError unless options['pool_file']
          options ||= { 'pool_file' => 'vmpool.yaml' }
          @pool_file = options['pool_file']
        end

        def update(content)
          write_content(content)
          read
        end

        def create
          write_content(base_content)
          read
        end

        def read
          puts "Reading snippet"
          read_content
        end

        def save
          write_content
          read
        end

        def pool_data
          @pool_data ||= YAML.load(read_content)
        end

        private

        def base_content
          {
            pool1: {
              pool_name: pool1,
              payload_file: pool1_payload.yaml,
              instances: 1,
              pool_instances: [],
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
