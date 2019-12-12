require 'net/http'
require 'timeout'
require 'openssl'
require 'uri'
require 'json'
require_relative 'base_store'

module Kitchen
  module Driver
    module VmpoolStores
      class VmpoolerStore < BaseStore
        attr_reader :vmpooler_url, :token, :tags, :lifetime, :ssl_verify, :ssl_cert

        # @param [Hash] opts
        # @option opts [String] :host_url The hostname to use in http requests.
        # @option opts [String] :user (nil) A username for authentication. Optional only if token is valid.
        # @option opts [String] :password (nil) A password for authentication. Optional only if token is valid.
        # @option opts [String] :token (nil) A preloaded token to use in requests. Optional only if
        #                                       user and pass are valid.
        # @raise [InvalidUrl] if vmpooler url is invalid
        def initialize(opts = {})
          host_url = opts.fetch('host_url')
          user = opts.fetch('user', nil)
          pass = opts.fetch('pass', nil)
          token = opts.fetch('token', nil)
          @ssl_cert = opts.fetch('ssl_cert', nil)
          @tags = opts.fetch('tags', { purpose: 'vmpooler-default' })
          @lifetime = opts.fetch('lifetime', nil)
          raise ArgumentError, "Invalid host_url: #{host_url}" if host_url.nil? 
          @vmpooler_url = URI.join(host_url, '/api/v1/').to_s
          raise Kitchen::Driver::InvalidUrl.new("Bad url: #{vmpooler_url}") unless valid_url?(URI.join(vmpooler_url, 'vm'))
          @token = valid_token?(token) ? token : create_token(user, pass)
          @ssl_verify = opts.fetch('ssl_verify', true)
        end

        # @param pool_name [String] the pool to take from
        # @return [String] a pool member from the pool
        def take_pool_member(pool_name)
          fetch_pool_member(pool_name)
        end

        # @param pool_member [String] the pool member to destroy
        def cleanup(pool_member:, pool_name: nil, reuse_instances: false)
          used_status = 'destroyed'
          destroy_pool_member(pool_member)
          yield(pool_member, used_status) if block_given?
        end

        private

        # @return [Hash] - returns hash of frequently used http options
        # @param uri [URI] - the uri to be api call
        def request_options(uri)
          {
            use_ssl: uri.scheme == 'https',
            ssl_version: :SSLv3,
            verify_mode: verify_mode(uri),
            ca_file: ca_cert_file
          }
        end

        # @return [Constant] - the verification mode to use
        def verify_mode(uri)
          return OpenSSL::SSL::VERIFY_NONE if uri.scheme == 'https'
          @ssl_verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
        end

        # @return [String] - the expanded path to the ca cert file, nil if not provided
        def ca_cert_file
          File.expand_path(@ssl_cert) unless @ssl_cert.nil? || @ssl_cert.empty?
        end

        # @param token [String] the token to validate
        # @return [true] if the token url is valid
        # @return [false] if the token url is invalid
        def valid_token?(token)
          if token and token.length > 5
            token_url = URI.join(vmpooler_url, 'token', token).to_s
            valid_url?(token_url)
          end
        end

        # @param url [String] a url to validate
        # @return [true] if the http response code is 200
        # @return [false] if the http response code is not 200
        def valid_url?(url)
          if url
            uri = URI(url)
            response = Net::HTTP.get_response(uri)
            response.code == '200'
          end
        end

        # @param pool_member [String] a VM instance to destroy
        # @raise [PoolMemberNotFound] if the pool member was not found
        # @raise [PoolMemberNotDestroyed] if the pool member was not destroyed
        def destroy_pool_member(pool_member)
          return true if destroyed?(pool_member)

          uri = URI.join(vmpooler_url, 'vm/', pool_member)
          request = Net::HTTP::Delete.new(uri)
          request.add_field('X-AUTH-TOKEN', token) if token
          req_options = request_options(uri) 
          response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
          end

          case
          when response.code == '200'
            "#{pool_member} successfully destroyed"
          when response.code == '404'
            raise Kitchen::Driver::PoolMemberNotFound.new("Pool member #{pool_member} was not found")
          else 
            raise Kitchen::Driver::PoolMemberNotDestroyed.new("Error destroying pool member: code #{response.code}, message #{response.body}")
          end
        end

        def vm_status(vm)
          vm_metadata(vm).fetch('state', nil)
        end

        def destroyed?(vm)
          vm_status(vm).eql?('destroyed')
        end

        def online?(vm)
          ! vm_status(vm).eql?('destroyed')
        end

        def vm_metadata(vm)
          uri = URI.join(vmpooler_url, 'vm/', vm)
          request = Net::HTTP::Get.new(uri)
          request.add_field('X-AUTH-TOKEN', token) if token
          req_options = request_options(uri) 
          response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
          end
          case response.code
          when '200'
            JSON.parse(response.body).fetch(vm, {})
          when '503'
            raise Kitchen::Driver::PoolMemberUnavailable.new(msg)
          when '404'
            raise Kitchen::Driver::PoolMemberNotFound.new("VM #{vm} was not found")
          else
            raise Exception.new("Error: code #{response.code}, message #{response.body}")
          end
        end

        # @param user [String]
        # @param pass [String]
        # @return [String] a new token if the http response code is 200
        # @raise [InvalidCredentials] if the http response code is 401
        # @raise [TokenNotCreated] if the http response code is otherwise not 200
        def create_token(user, pass)
          if user.nil? || user.empty?
            return nil 
          end
          uri = URI.join(vmpooler_url, 'token')
          request = Net::HTTP::Post.new(uri)
          request.basic_auth(user, pass)
          req_options = request_options(uri) 
          response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
          end

          return JSON.parse(response.body)['token'] if response.code == '200'
          raise Kitchen::Driver::InvalidCredentials.new("Username or password are invalid") if response.code == '401'
          raise Kitchen::Driver::TokenNotCreated.new("Unable to create token, got response code: #{response.code}")
        end

        # @return Array[String] - array of hostnames
        # @param pool_name [String] - the name of the pool to get hostnames from
        # @param number_of_vms [Integer] - a postive number of vms to fetch
        def fetch_pool_member(pool_name, number_of_vms = 1)
          uri = URI.join(vmpooler_url, 'vm')
          request = Net::HTTP::Post.new(uri)
          request.body = JSON.dump({ pool_name => number_of_vms.to_s })
          request.add_field('X-AUTH-TOKEN', token) if token
          req_options = request_options(uri) 
          response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
          end

          case response.code
          when '200'
            data = JSON.parse(response.body)
            "#{data[pool_name]['hostname']}.#{data[pool_name]['domain']}"
          when '503'
            msg = "Pool #{pool_name} does not have enough active pool members, please try later."
            raise Kitchen::Driver::PoolMemberUnavailable.new(msg)
          when '404'
            raise Kitchen::Driver::PoolNotFound.new("Pool #{pool_name} was not found")
          else
            raise Exception.new("Error: code #{response.code}, message #{response.body}")
          end
        end
      end
    end
  end
end
