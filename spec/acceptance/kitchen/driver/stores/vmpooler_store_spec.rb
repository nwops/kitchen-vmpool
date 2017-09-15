require 'spec_helper'
require 'kitchen/driver/vmpool_stores/vmpooler_store'
require 'net/http'
require 'json'

RSpec.describe 'vmpooler store' do
  let(:user) { 'jdoe' }
  let(:pass) { 'jdoe123' }
  let(:token) { nil }
  let(:driver_config) do
    {
        :state_store=> 'vmpooler',
        :store_options => {
            user: user,
            pass: pass,
            token: token,
            host_url: 'http://localhost:8080',
        },
    }
  end
  let(:store) { Kitchen::Driver::Vmpool.new(driver_config).send(:store) }
  let(:pool_name) { 'debian-7-i386' }

  before(:each) do
    1.upto(60) do
      break if is_ready?('http://localhost:8080/status')
      sleep(1)
    end
  end

  describe '#token' do
    valid_token_length = 32

    context 'when the given token is invalid' do
      let(:token) { nil }

      context 'when the credentials are right' do
        let(:user) { 'jdoe' }
        let(:pass) { 'jdoe123' }

        it 'creates a valid token' do
          expect(store.token.length).to eq(valid_token_length)
        end
      end

      context 'when the credentials are wrong' do
        let(:user) { 'jdoe' }
        let(:pass) { 'jdoe' }

        it 'raises InvalidCredentials' do
          expect { store }.to raise_exception(Kitchen::Driver::InvalidCredentials)
        end
      end
    end
  end

  describe '#vmpooler_url' do
    let(:endpoint) { '/api/v1/' }

    it 'includes the endpoint' do
      expect(store.vmpooler_url).to eq('http://localhost:8080' + endpoint)
    end
  end

  describe '#take_pool_member' do
    context 'when a pool member is available' do
      it 'returns the pool member' do
        pool_member = store.take_pool_member(pool_name)
        expect(pool_member).to match(/\Apoolvm-\w+/)
      end
    end

    context 'when no pool members are available' do
      it 'raises PoolMemberUnavailable' do
        expect { 1.upto(6) { store.take_pool_member(pool_name) } }.to raise_exception(Kitchen::Driver::PoolMemberUnavailable)
      end
    end

    context 'when the pool is not found' do
      it 'raises PoolNotFound' do
        expect { store.take_pool_member('bad_pool_name') }.to raise_exception(Kitchen::Driver::PoolNotFound)
      end
    end
  end

  describe '#cleanup' do
    context 'when the pool member is found' do
      it 'should not raise an exception' do
        expect { store.cleanup(pool_member: store.take_pool_member(pool_name)) }.to_not raise_exception
      end
    end

    context 'when the pool is not found' do
      it 'raises PoolNotFound' do
        expect { store.cleanup(pool_member: store.take_pool_member('bad_pool_name')) }.to raise_exception(Kitchen::Driver::PoolNotFound)
      end
    end
  end
end