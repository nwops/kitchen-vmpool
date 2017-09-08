require "kitchen/driver/vmpool_stores/gitlab_base_store"

module Kitchen
  module Driver
    module VmpoolStores
      class GitlabCommitStore < GitlabBaseStore

        attr_accessor :project_id
        attr_reader :pool_file, :branch

        # @option project_id [Integer] - the project id in gitlab
        # @option commit_id [Integer] - the snipppet id in the gitlab project
        # @option pool_file [String] - the snipppet file name
        def initialize(options = nil)
          # there is currently some sort of weird bug in gitlab that prevents us from creating files with a yaml extension
          # thus we have ranmed the default pool file to vmpool
          options ||= { "project_id" => nil, "pool_file" => 'vmpool'}
          raise ArgumentError.new("You must pass the project_id option") unless options['project_id'].to_i > 0
          @project_id = options['project_id']  #ie. 89
          @pool_file = options['pool_file'] || 'vmpool'
          @branch = 'master'
        end

        private

        def update(content = nil)
          #info("Updating vmpool data")
          update_file
          read
        end

        def create
          #info("Creating new vmpool data commit")
          create_file unless file_exists?
          read
        end

        def save
          # info("Saving vmpool data")
          update_file
          read
        end

        def file_exists?(project = project_id, file = pool_file)
          read_content(project, file)
        end

        def create_file(project = project_id)
          actions = [{
                         "action" => "create",
                         "file_path" => pool_file,
                         "content" => {}.to_yaml
                     }]
          client.create_commit(project, branch, "update vmpool data", actions)
        end


        def update_file(project = project_id)
          actions = [{
              "action" => "update",
              "file_path" => pool_file,
              "content" => pool_data.to_yaml
          }]
          client.create_commit(project, branch, "update vmpool data", actions)
        end

        def read_content(project = project_id, file = pool_file)
          begin
            client.file_contents(project, file, branch)
          rescue Gitlab::Error::NotFound
            false
          end
        end

      end
    end
  end
end
