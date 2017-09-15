require "bundler/setup"
require "kitchen/driver/vmpool"

def fixtures_dir
  @fixtures_dir ||= File.join(File.dirname(__FILE__), 'fixtures')
end

def is_ready?(url)
  make_get_request(url)['status']['ok']
end

def make_get_request(url)
  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  JSON.parse(response.body)
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
