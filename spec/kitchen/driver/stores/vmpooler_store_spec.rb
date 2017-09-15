require 'spec_helper'
require 'kitchen/driver/vmpool_stores/vmpooler_store'
require 'net/http'
require 'json'

RSpec.describe 'vmpooler store' do
  let(:user) { 'jdoe' }
  let(:pass) { user }
  let(:token) { 'token1' }
  let(:host_url) { 'http://www.example.com' }
  let(:driver_config) do
    {
        :state_store=> 'vmpooler',
        :create_command => nil,
        :destroy_command=>nil,
        :store_options => {
            user: user,
            pass: pass,
            token: token,
            host_url: host_url
        },
    }
  end
  let(:pool_name) { 'debian-7-i386' }
  let(:store) { Kitchen::Driver::Vmpool.new(driver_config).send(:store) }
  let(:ok) { instance_double('Net::HTTPResponse', code: '200') }
  let(:hostnames_found) { instance_double('Net::HTTPResponse', code: '200', body: File.read(File.join(fixtures_dir, 'vmpooler', 'debian_7_i386_ok.json'))) }
  let(:new_token_created) { instance_double('Net::HTTPResponse', code: '200', body: { token: 'token2' }.to_json) }
  let(:unauthorized) { instance_double('Net::HTTPResponse', code: '401') }
  let(:not_found) { instance_double('Net::HTTPResponse', code: '404') }
  let(:unavailable) { instance_double('Net::HTTPResponse', code: '503', body: File.read(File.join(fixtures_dir, 'vmpooler', 'not_ok.json'))) }

  describe '#new' do
    it 'returns a VmpoolerStore' do
      allow(Net::HTTP).to receive(:start).and_return(ok)
      expect(store).to be_a(Kitchen::Driver::VmpoolStores::VmpoolerStore)
    end

    context 'when vmpooler_url is not valid' do
      it 'raises InvalidUrl' do
        allow(Net::HTTP).to receive(:start).and_return(not_found)
        expect { store }.to raise_exception(Kitchen::Driver::InvalidUrl)
      end
    end
  end

  describe '#token' do
    context 'when the given token is valid' do
      it 'uses the token' do
        allow(Net::HTTP).to receive(:start).and_return(ok)
        expect(store.token).to eq(token)
      end
    end

    context 'when the given token is invalid' do
      it 'creates a new token' do
        allow(Net::HTTP).to receive(:start).and_return(ok, not_found, new_token_created)
        expect(store.token).to_not eq(token)
      end

      it 'raises TokenNotCreated when unauthorized' do
        allow(Net::HTTP).to receive(:start).and_return(ok, not_found, unauthorized)
        expect { store }.to raise_exception(Kitchen::Driver::InvalidCredentials)
      end
    end
  end

  describe '#vmpooler_url' do
    let(:endpoint) { '/api/v1/' }

    it 'includes the endpoint' do
      allow(Net::HTTP).to receive(:start).and_return(ok)
      expect(store.vmpooler_url).to eq(host_url + endpoint)
    end
  end

  describe '#take_pool_member' do
    context 'when hostnames are found' do
      it 'returns a hostname from a given pool' do
        allow(Net::HTTP).to receive(:start).and_return(ok, hostnames_found)
        hostnames = JSON.parse(hostnames_found.body)[pool_name]['hostname']
        hostname = store.take_pool_member(pool_name)
        expect(hostnames).to include(hostname)
      end
    end

    context 'when pool is not found' do
      it 'raises PoolNotFound' do
        allow(Net::HTTP).to receive(:start).and_return(ok, ok, not_found)
        expect { store.take_pool_member(pool_name) }.to raise_exception(Kitchen::Driver::PoolNotFound)
      end
    end

    context 'when pool is unavailable' do
      it 'raises PoolMemberUnavailable' do
        allow(Net::HTTP).to receive(:start).and_return(ok, ok, unavailable)
        expect { store.take_pool_member(pool_name) }.to raise_exception(Kitchen::Driver::PoolMemberUnavailable)
      end
    end
  end

  describe '#cleanup' do
    let(:opts) do
      {
          pool_member: 'pool_member_1'
      }
    end

    context 'when the pool member is successfully deleted' do
      it 'returns true' do
        allow(Net::HTTP).to receive(:start).and_return(ok, ok)
        expect { store.cleanup(opts) }.to_not raise_exception
      end
    end

    context 'when the pool member is not found' do
      it 'raises PoolMemberNotFound' do
        allow(Net::HTTP).to receive(:start).and_return(ok, ok, not_found)
        expect { store.cleanup(opts) }.to raise_exception(Kitchen::Driver::PoolMemberNotFound)
      end
    end

    context 'when the pool member is not destroyed' do
      it 'raises PoolMemberNotDestroyed' do
        allow(Net::HTTP).to receive(:start).and_return(ok, ok, unavailable)
        expect { store.cleanup(opts) }.to raise_exception(Kitchen::Driver::PoolMemberNotDestroyed)
      end
    end
  end
end