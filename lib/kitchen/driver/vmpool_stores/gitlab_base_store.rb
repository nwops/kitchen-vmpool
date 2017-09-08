require 'gitlab'
require "kitchen/driver/vmpool_stores/file_base_store"
require 'yaml'

module Kitchen
  module Driver
    module VmpoolStores
      class GitlabBaseStore < FileBaseStore

        private

        def client
          @client ||= Gitlab.client
        end

      end
    end
  end
end

# monkey patch error in error code until it is fixed upstream
module Gitlab
  module Error
    class ResponseError
      # Human friendly message.
      #
      # @return [String]
      private
      def build_error_message
        parsed_response = @response.parsed_response
        message = parsed_response.respond_to?(:message) ? parsed_response.message : parsed_response['message']
        message = parsed_response.error unless message
        "Server responded with code #{@response.code}, message: " \
        "#{handle_message(message)}. " \
        "Request URI: #{@response.request.base_uri}#{@response.request.path}"
      end
    end
  end
end

