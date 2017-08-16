require "spec_helper"
require 'kitchen/driver/vmpool'
require 'kitchen/driver/vmpool_stores/file_store'
require 'kitchen/driver/vmpool_stores/gitlab_store'
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

  # let(:pool_data) do

  # end
  #
  # let(:used_instances) do
  #   pool_data["used_instances"]
  # end
  #
  # let(:pool_instances) do
  #   pool_data["pool_instances"]
  # end

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

  describe 'filestore' do
    let(:driver_config) do
      {
        :pool_name=>"pool1",
        store_options: {
          pool_file: File.join(fixtures_dir, 'vmpool.yaml')
        },
        :state_store=>"file",
        :destroy_command=>nil
      }
    end

    it 'create a file based store' do
      expect(vmpool.send(:store)).to be_a Kitchen::Driver::VmpoolStores::FileStore
    end

    it 'create returns a vm' do
      member = vmpool.create(state)
      expect(member).to match(/vm\d/)
    end

    it 'removes from pool instances' do
      before = pool_data['pool_instances'].count
      member = vmpool.create(state)
      expect(pool_data['pool_instances'].count).to be < before
    end

    it 'adds to used instances' do
      before = (pool_data['used_instances'] || []).count
      member = vmpool.create(state)
      expect(pool_data['used_instances'].count).to be > before
    end

    it 'destroy and not resuable' do
      member = vmpool.create(state)
      expect(pool_data['pool_instances']).to_not include(member)
      driver_config.merge({reuse_instances: false})
      vmpool.destroy({hostname: member})
      expect(pool_data['pool_instances']).to_not include(member)
      expect(pool_data['used_instances']).to include(member)
    end

    describe 'reusable' do

      let(:driver_config) do
        {
            :pool_name=>"pool1",
            store_options: {
                pool_file: File.join(fixtures_dir, 'vmpool.yaml')
            },
            :state_store=>"file",
            :destroy_command=>nil,
            reuse_instances: true
        }
      end

      it 'destroy and resuable' do
        member = vmpool.create(state)
        vmpool.destroy({hostname: member})
        expect(pool_data['used_instances']).to_not include(member)
        expect(pool_data['pool_instances']).to include(member)
      end

    end


    describe 'empty pool' do
      let(:driver_config) do
        {
          :pool_name=>"pool1",
          store_options: {
            pool_file: File.join(fixtures_dir, 'empty_vmpool.yaml')
          },
          :state_store=>"file",
          :destroy_command=>nil
        }
      end

      it 'create' do
        expect{vmpool.create(state)}.to raise_error(Kitchen::Driver::PoolMemberNotFound)
      end

      it 'destroy' do
        expect(vmpool.destroy({hostname: nil})).to be_nil
      end
    end

    describe 'reuse instances' do
      let(:driver_config) do
        {
          :pool_name=>"pool1",
          store_options: {
            pool_file: File.join(fixtures_dir, 'reused_vmpool.yaml')
          },
          :reuse_instances => true,
          :state_store=>"file",
          :destroy_command=>nil,
          reuse_instances: true
        }
      end

      it 'create' do
        vmpool.destroy({hostname: 'vm4'})
        expect(vmpool.create(state)).to match(/vm4/)
      end

      it 'destroy' do
        expect(vmpool.destroy({hostname: 'vm4'})).to eq('vm4')
      end
    end

  end

  describe 'gitlab' do

    let(:state) do
      {

      }
    end

    let(:driver_config) do
      {
        :pool_name=>"pool1",
        :state_store=>"gitlab",
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
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabStore).to receive(:save).and_return(true)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabStore).to receive(:create).and_return(data)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabStore).to receive(:update).and_return(data)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabStore).to receive(:read_content).and_return(data)
      allow_any_instance_of(Kitchen::Driver::VmpoolStores::GitlabStore)
       .to receive(:read).and_return(File.read(file))

    end

    it 'create a gitlab based store' do
      expect(vmpool.send(:store)).to be_a Kitchen::Driver::VmpoolStores::GitlabStore
    end

    it 'create' do
      expect(vmpool.create(state)).to match(/vm\d/)
    end

    it 'destroy' do
      expect(vmpool.destroy({hostname: 'vm1'})).to eq('vm1')
    end
  end

end
