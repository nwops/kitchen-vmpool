require 'spec_helper'
require 'kitchen/driver/vmpool'
RSpec.describe 'snippet store' do

  let(:driver_config) do
    {
        :pool_name=>"pool1",
        store_options: {
            snippet_id: '1',
            project_id:  '3941728',
            pool_file: File.join(fixtures_dir, 'vmpool.yaml')
        },
        :create_command => nil,
        :state_store=> 'gitlab_snippet',
        :destroy_command=>nil
    }
  end

  let(:vmpool) do
    Kitchen::Driver::Vmpool.new(driver_config)
  end

  let(:store) do
    vmpool.send(:store)
  end

  it '#new' do
    expect(store).to be_a(Kitchen::Driver::VmpoolStores::GitlabSnippetStore)
  end
end
