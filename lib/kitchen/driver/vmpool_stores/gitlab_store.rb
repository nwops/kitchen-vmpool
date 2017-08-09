require 'gitlab'
module Kitchen
  module Driver
    module VmpoolStores
      class GitlabStore

        attr_accessor :project_id, :snippet_id
        attr_reader :pool_file

        def initialize(options = nil)
          options ||= { project_id: 89, snippet_id: 630, pool_file: 'vmpool.yaml'}
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
          puts read_snippet
        end

        def pool_data
          YAML.load(pool_content)
        end

        private

        def client
          @client ||= Gitlab.client
        end

        def pool_content
          read_snippet
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
            code: pool_content
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
