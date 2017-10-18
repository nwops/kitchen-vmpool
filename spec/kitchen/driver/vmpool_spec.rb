require "spec_helper"
require 'kitchen/driver/vmpool'
require 'kitchen/driver/vmpool_stores/file_store'
require 'kitchen/driver/vmpool_stores/gitlab_snippet_store'
require 'kitchen/driver/vmpool_stores/gitlab_commit_store'

RSpec.describe Kitchen::Driver::Vmpool do

  let(:vmpool) do
    Kitchen::Driver::Vmpool.new(driver_config)
  end

  let(:store) do
    vmpool.send(:store)
  end

  def pool_data
    pool_name = driver_config[:pool_name]
    store.pool_data(false)[pool_name]
  end

  let(:state) do
    {

    }
  end

  before(:each) do
    allow_any_instance_of(Kitchen::Driver::VmpoolStores::FileStore).to receive(:save).and_return(true)
  end

  let(:driver_config) do
    {
      :pool_name=>"pool1",
      store_options: {
        pool_file: File.join(fixtures_dir, 'vmpool.yaml')
      },
      :create_command => nil,
      :state_store=> 'file',
      :destroy_command=>nil
    }
  end

  it "does something useful" do
    expect(vmpool).to be_a Kitchen::Driver::Vmpool
  end


  describe 'gitlab_snippet' do

    let(:state) do
      {

      }
    end

    let(:driver_config) do
      {
        :pool_name=>"pool1",
        :state_store=>"gitlab_snippet",
        store_options: {
          snippet_id: 30,
          project_id: 630,
          pool_file: File.join(fixtures_dir, 'vmpool.yaml')
        },
        :destroy_command=>nil
      }
    end

    before(:each) do
      file = driver_config[:store_options][:pool_file]
      data = File.read(file)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabSnippetStore).to receive(:save).and_return(true)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabSnippetStore).to receive(:create).and_return(data)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabSnippetStore).to receive(:update).and_return(data)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabSnippetStore).to receive(:read_content).and_return(data)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabSnippetStore)
       .to receive(:read).and_return(File.read(file))

    end

    it 'create a gitlab based store' do
      expect(vmpool.send(:store)).to be_a Kitchen::Driver::VmpoolStores::GitlabSnippetStore
    end

    it 'create' do
      expect(vmpool.create(state)).to match(/vm\d/)
    end

    it 'destroy' do
      expect(vmpool.destroy({hostname: 'vm1'})).to eq('vm1')
    end
  end

  describe 'gitlab_commit' do

    let(:state) do
      {

      }
    end

    let(:driver_config) do
      {
          :pool_name=>"pool1",
          store_options: {
              project_id:  '3941728',
              pool_file: File.join(fixtures_dir, 'vmpool.yaml')
          },
          :create_command => nil,
          :state_store=> 'gitlab_commit',
          :destroy_command=>nil
      }
    end

    before(:each) do
      file = driver_config[:store_options][:pool_file]
      data = File.read(file)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabSnippetStore).to receive(:save).and_return(true)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabSnippetStore).to receive(:create).and_return(data)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabSnippetStore).to receive(:update).and_return(data)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabSnippetStore).to receive(:read_content).and_return(data)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabSnippetStore)
          .to receive(:read).and_return(File.read(file))

    end

    it 'create a gitlab based store' do
      expect(vmpool.send(:store)).to be_a Kitchen::Driver::VmpoolStores::GitlabCommitStore
    end

    it 'create' do
      #expect(vmpool.create(state)).to match(/vm\d/)
    end
    #
    # it 'destroy' do
    #   expect(vmpool.destroy({hostname: 'vm1'})).to eq('vm1')
    # end
  end

end
