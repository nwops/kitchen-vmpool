require 'yaml'

module Kitchen
  module Driver
    module VmpoolStores
      class FileStore

        attr_reader :pool_file

        def initialize(options = nil)
          options ||= { pool_file: 'vmpool.yaml' }
          @pool_file = options[:pool_file]
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
          puts read_content
        end

        def pool_data
          @pool_content ||= YAML.load(read_content)
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
          File.read(pool_name)
        end



        def write_content(content = pool_data)
          File.open(pool_file, 'w') { |f| f.write(content.to_yaml) }
        end

      end
    end
  end
end
