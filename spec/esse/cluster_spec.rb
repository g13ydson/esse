# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Cluster do
  let(:model) { described_class.new(id: :v1) }

  describe '.id' do
    context do
      let(:model) { described_class.new(id: :v1) }

      it { expect(model.id).to eq(:v1) }
    end

    context do
      let(:model) { described_class.new(id: 'v2') }

      it { expect(model.id).to eq(:v2) }
    end
  end

  describe 'initialization properties' do
    specify do
      model = described_class.new(id: :v1)
      expect(model.index_settings).to eq({})
    end

    specify do
      model = described_class.new(id: :v1, index_settings: { refresh_interval: '1s' })
      expect(model.index_settings).to eq(refresh_interval: '1s')
    end
  end

  describe '.assign' do
    let(:model) { described_class.new(id: :v1) }

    specify do
      expect(model.index_settings).to eq({})
      expect { model.assign(index_settings: { refresh_interval: '1s' }, other: 1) }.not_to raise_error
      expect(model.index_settings).to eq(refresh_interval: '1s')
    end

    specify do
      expect(model.index_settings).to eq({})
      expect { model.assign('index_settings' => { 'refresh_interval' => '1s' }, 'other' => 1) }.not_to raise_error
      expect(model.index_settings).to eq('refresh_interval' => '1s')
    end

    specify do
      expect(model.wait_for_status).to eq(nil)
      expect { model.assign(wait_for_status: 'yellow') }.not_to raise_error
      expect(model.wait_for_status).to eq('yellow')
    end
  end

  describe '.wait_for_status' do
    it { expect(model.wait_for_status).to eq(nil) }

    it 'sets the value for wait_for_status' do
      model.wait_for_status = 'green'
      expect(model.wait_for_status).to eq('green')
    end
  end

  describe '.wait_for_status!' do
    let(:client) { instance_double(Elasticsearch::Transport::Client) }

    before { model.client = client }

    it 'checks for the cluster health using the given status' do
      expect(client).to receive(:cluster).and_return(cluster_api = double)
      expect(cluster_api).to receive(:health).with(wait_for_status: 'green').and_return(:ok)
      expect(model.wait_for_status!(status: 'green')).to eq(:ok)
    end

    it 'checks for the cluster health using the status from config' do
      expect(client).to receive(:cluster).and_return(cluster_api = double)
      expect(cluster_api).to receive(:health).with(wait_for_status: 'yellow').and_return(:ok)
      model.wait_for_status = :yellow
      expect(model.wait_for_status!).to eq(:ok)
    end

    it 'does not sends any request to elasticsearch when wait for status is not defined' do
      expect(client).not_to receive(:cluster)
      expect(model.wait_for_status!).to eq(nil)
    end
  end

  describe '.index_settings' do
    it { expect(model.index_settings).to eq({}) }

    it 'allows overwriting default value' do
      model.index_settings = { foo: 'bar' }
      expect(model.index_settings).to eq(foo: 'bar')
    end
  end

  describe '.index_prefix' do
    it { expect(model.index_prefix).to eq nil }

    it 'allows overwriting default value' do
      model.index_prefix = 'prefix'
      expect(model.index_prefix).to eq('prefix')
    end
  end

  describe '.client=' do
    it { expect(model).to respond_to(:"client=") }

    it 'defines a connection from hash' do
      expect(Elasticsearch::Client).to receive(:new).with(hosts: []).and_return(client = double)

      expect {
        model.client = { hosts: [] }
      }.not_to raise_error
      expect(model.client).to eq(client)
    end

    it 'allows set a Elasticsearch::Client instance as client' do
      client = Elasticsearch::Client.new
      expect {
        model.client = client
      }.not_to raise_error
      expect(model.client).to eq(client)
    end
  end

  describe '.client' do
    it { expect(model).to respond_to(:client) }

    it 'retuns an instance of elasticsearch as default' do
      expect(model.instance_variable_get(:@client)).to eq(nil)
      expect(model.client).to be_an_instance_of(Elasticsearch::Transport::Client)
      expect(model.instance_variable_get(:@client)).to be_an_instance_of(Elasticsearch::Transport::Client)
    end

    it 'store connection using default key' do
      expect(model.instance_variable_get(:@client)).to eq(nil)
      client = Elasticsearch::Client.new
      model.client = client
      expect(model.client).to eq(client)
      expect(model.instance_variable_get(:@client)).to eq(client)
    end
  end
end
