require 'yaml'

module Kitchen
  module Driver
    module VmpoolStores
      class BaseStore
        attr_reader :pool_file, :pool_data
        
        def update(content = nil)
          write_content(content)
          read
        end

        def create
          write_content(base_content)
          read
        end

        def read
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

        def read_content
          raise NotImplementedError
        end
      end
    end
  end
end
