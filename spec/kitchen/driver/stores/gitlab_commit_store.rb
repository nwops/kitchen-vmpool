require 'spec_helper'
require 'kitchen/driver/vmpool'
RSpec.describe 'commit store' do

  let(:driver_config) do
    {
        :pool_name=>"pool1",
        store_options: {
            project_id:  '3941728',
            pool_file: 'vmpool1.yaml'
        },
        :create_command => nil,
        :state_store=> 'gitlab_commit',
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
    expect(store).to be_a(Kitchen::Driver::VmpoolStores::GitlabCommitStore)
  end

  it '#exists?' do
    expect(store.file_exists?('3941728', 'vvpool2.yaml')).to be false
  end

  it '#create' do
    expect(store.create).to be true
  end

  it '#read' do
    expect(store.read).to_not be false
  end
end
