require "kitchen/driver/vmpool_stores/gitlab_base_store"
module Kitchen
  module Driver
    module VmpoolStores
      class GitlabSnippetStore < GitlabBaseStore

        attr_accessor :project_id, :snippet_id
        attr_reader :pool_file

        # @option project_id [Integer] - the project id in gitlab
        # @option snippet_id [Integer] - the snipppet id in the gitlab project
        # @option pool_file [String] - the snipppet file name
        def initialize(options = nil)
          options ||= { project_id: nil, snippet_id: nil, pool_file: 'vmpool'}
          raise ArgumentError.new("You must pass the project_id option") unless options['project_id'].to_i > 0
          @snippet_id = options['snippet_id']  #ie. 630
          @project_id = options['project_id']  #ie. 89
          @pool_file = options['pool_file']
        end

        def update(content = nil)
          #info("Updating vmpool data")
          update_snippet
          read
        end

        def create
          #info("Creating new vmpool data snippet")
          snippet = create_snippet
          @snippet_id = snippet.id
          read
        end

        def save
          #info("Saving vmpool data")
          update_snippet
          read
        end

        private

        def client
          @client ||= Gitlab.client
        end

        def snippet_exists?(project = project_id)
          return false unless snippet_id
          client.snippets(project, {
            title: 'Virtual Machine Pools',
            visibility: 'public',
            file_name: pool_file,
            code: {}.to_yaml})
        end

        def create_snippet(project = project_id)
          client.create_commit(project, {
            title: 'Virtual Machine Pools',
            visibility: 'public',
            file_name: pool_file,
            code: {}.to_yaml
            })
        end

        def update_snippet(project = project_id)
          client.edit_snippet(project, snippet_id, {
            title: 'Virtual Machine Pools',
            visibility: 'public',
            file_name: pool_file,
            code: pool_data.to_yaml
           })
        end

        def project_snippets(project = project_id)
          client.snippets(project).map {|s| s.id }
        end

        def read_content(project = project_id, id = snippet_id)
          client.snippet_content(project, id)
        end

      end
    end
  end
end
