require 'spec_helper'
require 'kitchen/driver/vmpool'
RSpec.describe 'file store' do

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

  def pool_data
    pool_name = driver_config[:pool_name]
    store.pool_data(false)[pool_name]
  end

  let(:state) do
    {

    }
  end

  let(:vmpool) do
    Kitchen::Driver::Vmpool.new(driver_config)
  end

  let(:store) do
    vmpool.send(:store)
  end

  it '#new' do
    expect(store).to be_a(Kitchen::Driver::VmpoolStores::FileStore)
  end

  describe 'filestore' do

    before(:each) do
      allow(store).to receive(:save).and_return(true)
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

      before(:each) do
        allow(store).to receive(:save).and_return(true)
      end

      it 'destroy puts back to instances' do
        member = vmpool.create(state)
        vmpool.destroy({hostname: member})
        expect(pool_data['pool_instances']).to include(member)
      end

      it 'removed from used' do
        member = vmpool.create(state)
        vmpool.destroy({hostname: member})
        expect(pool_data['used_instances']).to_not include(member)
      end

      it 'not added to garbage' do
        member = vmpool.create(state)
        vmpool.destroy({hostname: member})
        expect(pool_data['garbage_collection']).to be_nil
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

    describe 'not reuse instances' do
      before(:each) do
        allow(store).to receive(:save).and_return(true)
      end

      let(:driver_config) do
        {
            :pool_name=>"pool1",
            store_options: {
                pool_file: File.join(fixtures_dir, 'vmpool.yaml')
            },
            :reuse_instances => false,
            :state_store=>"file",
            :destroy_command=>nil,
        }
      end

      it 'destroy does not put back to instances' do
        member = vmpool.create(state)
        vmpool.destroy({hostname: member})
        expect(pool_data['pool_instances']).to_not include(member)
      end

      it 'removed from used' do
        member = vmpool.create(state)
        vmpool.destroy({hostname: member})
        expect(pool_data['used_instances']).to_not include(member)
      end

      it 'adds a garbage' do
        member = vmpool.create(state)
        vmpool.destroy({hostname: member})
        expect(pool_data['garbage_collection']).to be_a Array
      end

      it 'added to garbage' do
        member = vmpool.create(state)
        vmpool.destroy({hostname: member})
        expect(pool_data['garbage_collection']).to include(member)
      end

      it 'not contain duplicates' do
        member = vmpool.create(state)
        vmpool.destroy({hostname: member})
        vmpool.destroy({hostname: member})
        expect(pool_data['garbage_collection'].length).to eq(pool_data['garbage_collection'].uniq.length)
      end

      it 'create' do
        allow(pool_data).to receive(:[]).with('pool_instances').and_return(nil)
        expect{vmpool.create(state)}.to raise_error(Kitchen::Driver::PoolMemberNotFound)
      end

      it 'destroy' do
        expect(vmpool.destroy({hostname: 'vm4'})).to eq('vm4')
      end

    end
  end

end
