#!/usr/bin/env ruby
require 'vra'
require 'erb'
require 'highline/import'
require 'openssl'
require 'json'
require 'yaml'

# Purpose: Submits a single request to VRA for vm creation
module Vra
  class Client
    # monkey patch the init method to accept token
    def initialize(opts)
      @base_url     = opts[:base_url]
      @username     = opts[:username]
      @password     = PasswordMasker.new(opts[:password])
      @tenant       = opts[:tenant]
      @verify_ssl   = opts.fetch(:verify_ssl, true)
      @bearer_token = PasswordMasker.new(nil)
      @page_size    = opts.fetch(:page_size, 20)

      validate_client_options!
    end
  end

  # monkey patch the init method to accept additional params
  class CatalogRequest
    def initialize(client, catalog_id, opts = {})
      @client            = client
      @catalog_id        = catalog_id
      @cpus              = opts[:cpus]
      @memory            = opts[:memory]
      @requested_for     = opts[:requested_for]
      @lease_days        = opts[:lease_days]
      @notes             = opts[:notes]
      @subtenant_id      = opts[:subtenant_id]
      @additional_params = opts[:additional_params] || Vra::RequestParameters.new
      @catalog_item = Vra::CatalogItem.new(client, id: catalog_id)
    end
  end
end

module VraUtilities
  def classification
     ENV['VRA_CLASSIFY']
  end

  def branch
    `git rev-parse --abbrev-ref HEAD`.chomp if ENV['USE_BRANCH']
  end

  def sandbox
    branch || 'dev'
  end

  def datacenter
    ENV['DATACENTER'] || 'Eroc'
  end

  def vra_email
    @vra_email ||= ENV['VRA_EMAIL'] || ask('What is your frit email for VRA notifications')
  end

  def subtenant_id
    ENV['VRA_SUB_TENANT_ID']
  end

  def vra_user
    @vra_user ||= ENV['VRA_USER'] || ask('Enter User: ') {|q| q.echo = true}
  end

  def vra_pass
    @vra_pass ||= ENV['VRA_PASS'] || ask('Enter VRA Password: ') {|q| q.echo = 'x'}
  end

  def base_url
    @server ||= ENV['VRA_URL']
  end

  # @return [Hash] - the the hash value of the key_name found in the request data payload
  def data_item(key_name)
    request_data["requestData"]['entries'].find {|e| e["key"] == key_name }
  end

  # @return [String] - the value of the key_name found in the request data payload
  def data_item_value(key_name)
    item = data_item(key_name)
    return item if item.nil?
    item["value"]["value"]
  end

  # @return [VRA::Client] - creates a new client object and returns it
  def client
    @client ||= Vra::Client.new(
      username: vra_user,
      password: vra_pass,
      tenant: 'vsphere.local',
      base_url: base_url,
      verify_ssl: false,
     )
  end

  # @return Array[String] - returns an array of catalog items
  def catalog_items
   client.catalog.all_items.map {|i| {name: i.name, id: i.id}}
  end

  def request_options
    {
      cpus: data_item_value("provider-VirtualMachine.CPU.Count") || 1,
      memory: data_item_value("provider-VirtualMachine.Memory.Size") || 4096,
      requested_for: ENV['VRA_USER'] || data_item_value("requestedFor"),
      lease_days: 2,
      additional_params: request_params,
      notes: 'VRA Server Pool Test',
      subtenant_id: request_data['organization']['subtenantRef']
    }
  end

  def request_data
    @request_data ||= YAML.load_file(@payload_file)
  end

  def parameters
    request_data['requestData']['entries'].map {|item| [item['key'], item['value'].values].flatten }
  end

  def request_params
    unless @request_params
      @request_params = Vra::RequestParameters.new
      parameters.each { |p| @request_params.set(*p)}
    end
    @request_params
  end

  def request_item
     blueprint = request_data['catalogItemRef']['id']
     client.catalog.request(blueprint, request_options)
  end

  # @return [Vra::Request] - returns a request item
  def submit_new_request(payload_file)
    @payload_file = payload_file
    request_item.submit
  end

  require 'optparse'

  def run
  	cli_options = {}
  	o = OptionParser.new do |opts|
  	  opts.program_name = 'vra-pool'
  	  opts.on_head(<<-EOF

    Summary: A tool used to provision systems in VRA
  	  EOF
  	  )
  	  opts.on('-n', '--node-file FILE', "Load the request data from this file and create it") do |c|
  	    cli_options[:node_file] = c
  	  end
  	end.parse!
   submit_new_request(cli_options[:node_file]) if File.exist?(cli_options[:node_file]) # create the request
  end
end

include VraUtilities
