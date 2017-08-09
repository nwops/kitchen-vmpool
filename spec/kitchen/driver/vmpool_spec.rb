require "spec_helper"
require 'kitchen/driver/vmpool'

RSpec.describe Kitchen::Driver::Vmpool do

  let(:pool) do
    Kitchen::Driver::Vmpool.new
  end

  let(:config) do
    {:sudo=>true, :port=>22,
      :max_ssh_sessions=>9,
      :pool_name=>"pool1",
      :pool_file=>"vmpool.yaml",
      :state_store=>"file",
      :store_options=>{},
      :destroy_command=>nil
    }
  end

  before(:each) do
    allow(pool).to receive(:config).and_return(config)
  end

  describe 'file' do
    let(:config) do
      {:sudo=>true, :port=>22,
        :max_ssh_sessions=>9,
        :pool_name=>"pool1",
        :pool_file=>"vmpool.yaml",
        :state_store=>"file",
        :store_options=>{},
        :destroy_command=>nil
      }
    end

    it 'create a file based store' do
      expect(pool.send(:store)).to be_a Kitchen::Driver::VmpoolStores::FileStore
    end
  end

  it "does something useful" do
    expect(pool).to be_a Kitchen::Driver::Vmpool
  end


  describe 'gitlab' do
    let(:config) do
      {:sudo=>true, :port=>22,
        :max_ssh_sessions=>9,
        :pool_name=>"pool1",
        :pool_file=>"vmpool.yaml",
        :state_store=>"gitlab",
        :store_options=>{},
        :destroy_command=>nil
      }
    end

    it 'create a gitlab based store' do
      expect(pool.send(:store)).to be_a Kitchen::Driver::VmpoolStores::GitlabStore
    end
  end

end
