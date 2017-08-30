#!/usr/bin/env ruby
require 'vra'
require 'fileutils'
require 'erb'
require 'highline/import'
require 'openssl'
require 'json'
require 'yaml'

# Purpose: Submits a single request to VRA for vm creation


# monkey patch strings to symbols until we can patch upstream
module Vra
  class CatalogRequest
    attr_accessor :template_payload

    def template_payload
      @template_payload ||= dump_template(@catalog_id) 
    end

    def template_payload=(payload)
      @template_payload = payload
    end

    def write_template(id, filename = nil)
      filename ||= "#{id}.json" 
      begin
        puts "Writing file #{filename}"
        contents = dump_template(id)
        data = JSON.parse(contents)
        pretty_contents = JSON.pretty_generate(data)
        File.write(filename, pretty_contents)
      rescue Vra::Exception::HTTPError => e
        puts e.message
      end
    end

    def dump_template(id)
      response = client.http_get("/catalog-service/api/consumer/entitledCatalogItems/#{id}/requests/template")
      response.body
    end

    def merged_payload
       merge_payload(template_payload)
    end

    def submit
      validate_params!

      begin
        post_response = client.http_post("/catalog-service/api/consumer/entitledCatalogItems/#{@catalog_id}/requests", merged_payload)
      rescue Vra::Exception::HTTPError => e
        raise Vra::Exception::RequestError, "Unable to submit request: #{e.errors.join(', ')}"
      rescue
        raise
      end

      request_id = JSON.parse(post_response.body)["id"]
      Vra::Request.new(client, request_id)
    end

  end
  class RequestParameters
    def set_parameters(key, value_data, parent = nil)
      value_type = value_data[:type] || value_data['type']
      data_value = value_data[:value] || value_data['value']
      if value_type
        if parent.nil?
          set(key, value_type, data_value)
        else
          parent.add_child(Vra::RequestParameter.new(key, value_type, data_value))
        end
      else
        if parent.nil?
          p = set(key, nil, nil)
        else
          p = Vra::RequestParameter.new(key, nil, nil)
          parent.add_child(p)
        end

        value_data.each do |k, data|
          set_parameters(k, data, p)
        end
      end
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
    ENV['DATACENTER']
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

  def template_data
    @template_data ||= JSON.parse(File.read(@payload_file))
  end

  def request_options
    {
      cpus: template_data['data']['Machine']['data']['cpu'] || 2,
      memory: template_data['data']['Machine']['data']['memory'] || 4096,
      requested_for: ENV['VRA_USER'] 
      lease_days: 2,
      notes: 'VRA Server Pool Test',
      subtenant_id: template_data['businessGroupId']
    }
  end

  def catalog_request 
     blueprint = template_data['catalogItemId']
     cr = client.catalog.request(blueprint, request_options)
     cr.template_payload = File.read(@payload_file)
     cr
  end

  # @return [Vra::Request] - returns a request item
  def submit_new_request(file)
    @payload_file = File.expand_path(file)
    unless @payload_file and File.exist?(@payload_file)
      puts "The payload file: #{@payload_file} does not exist"
      exit -1 
    end
    cr = catalog_request 
    cr.submit
  end

  require 'optparse'

  def dump_templates(dir_name = 'vra7_templates')
    FileUtils.mkdir(dir_name) unless File.exist?(dir_name)
    catalog_items.each do |c|
      cr = catalog_request
      filename = File.join(dir_name, "#{c[:name]}.json".gsub(' ', '_')).downcase
      cr.write_template(c[:id], filename)
    end
  end


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
          opts.on('-t', '--dump-templates', "Dump all catalog templates") do |c|
            cli_options[:dump_templates] = true
          end
        end.parse!
   @payload_file = cli_options[:node_file]
   dump_templates if cli_options[:dump_templates]
   submit_new_request(@payload_file) 
  end
end
include VraUtilities
