require 'gitlab'
module Kitchen
  module Driver
    module VmpoolStores
      class GitlabStore

        attr_accessor :project_id, :snippet_id
        attr_reader :pool_file

        # @option project_id [Integer] - the project id in gitlab
        # @option snippet_id [Integer] - the snipppet id in the gitlab project
        # @option pool_file [String] - the snipppet file name
        def initialize(options = nil)
          options ||= { project_id: nil, snippet_id: nil, pool_file: 'vmpool.yaml'}
          raise ArgumentError.new("You must pass the project_id option") unless options[:project_id].to_i > 0
          raise ArgumentError.new("You must pass the snippet_id option") unless options[:snippet_id].to_i > 0
          @snippet_id = options[:snippet_id]  #ie. 630
          @project_id = options[:project_id]  #ie. 89
          @pool_file = options[:pool_file]
        end

        def update
          update_snippet
          read
        end

        def create
          create_snippet
          read
        end

        def read
          puts "Reading snippet"
          pool_content
        end

        def pool_data
          @pool_data ||= YAML.load(pool_content)
        end

        def save
          update_snippet
          read
        end

        def pool_content
          read_snippet
        end

        private

        def client
          @client ||= Gitlab.client
        end

        def snippet_exists?(project = project_id)
          client.snippets(project, {
            title: 'Virtual Machine Pools',
            visibility: 'public',
            file_name: pool_file,
            code: pool_content})
        end

        def create_snippet(project = project_id)
          client.create_snippet(project, {
            title: 'Virtual Machine Pools',
            visibility: 'public',
            file_name: pool_file,
            code: pool_content
            })
        end

        def update_snippet(project = project_id)
          client.edit_snippet(project, snippet_id, {
            title: 'Virtual Machine Pools',
            visibility: 'public',
            file_name: pool_file,
            code: pool_data
           })
        end

        def project_snippets(project = project_id)
          client.snippets(project).map {|s| s.id }
        end

        def read_snippet(project = project_id, id = snippet_id)
          client.snippet_content(project, id)
        end

      end
    end
  end
end
