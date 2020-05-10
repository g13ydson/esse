# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Backend::Index do
  before do
    stub_index(:dummies)
  end

  describe '.exist?' do
    context 'when index does not exists' do
      specify do
        es_client { expect(DummiesIndex.backend.exist?).to eq(false) }
      end
    end

    context 'when index exists' do
      specify do
        es_client do
          DummiesIndex.backend.create_index!
          expect(DummiesIndex.backend.exist?).to eq(true)
        end
      end
    end
  end

  describe '.delete' do
    specify do
      es_client do
        expect(DummiesIndex.backend.delete(suffix: nil)).to eq(false)
      end
    end

    specify do
      es_client do
        expect(DummiesIndex.backend.delete(suffix: 'v1')).to eq(false)
      end
    end

    specify do
      es_client do
        expect(DummiesIndex.backend.create_index(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.delete(suffix: 'v1')['acknowledged']).to eq(true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.create_index(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.delete(suffix: nil)['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v2")).to eq(true)
      end
    end
  end

  describe '.delete!' do
    specify do
      es_client do
        expect { DummiesIndex.backend.delete!(suffix: nil) }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
      end
    end

    specify do
      es_client do
        expect { DummiesIndex.backend.delete!(suffix: 'v1') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
      end
    end

    specify do
      es_client do
        expect(DummiesIndex.backend.create_index(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.delete!(suffix: 'v1')['acknowledged']).to eq(true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.create_index(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.delete!(suffix: nil)['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v2")).to eq(true)
      end
    end
  end

  describe '.update_aliases' do
    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.update_aliases(suffix: 'v1')).to eq(false)
        expect(DummiesIndex.backend.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect(DummiesIndex.backend.update_aliases(suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create_index(alias: true, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create_index(alias: false, suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v2")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v3")).to eq(true)
        expect(client.indices.get_alias(index: "#{cluster.index_prefix}_dummies")).to eq(
          "#{cluster.index_prefix}_dummies_v2" => {
            'aliases' => {
              "#{cluster.index_prefix}_dummies" => {},
            },
          },
        )
        expect(DummiesIndex.backend.update_aliases(suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.get_alias(index: "#{cluster.index_prefix}_dummies")).to eq(
          "#{cluster.index_prefix}_dummies_v3" => {
            'aliases' => {
              "#{cluster.index_prefix}_dummies" => {},
            },
          },
        )
      end
    end
  end

  describe '.update_aliases!' do
    specify do
      es_client do |client, _conf, cluster|
        expect { DummiesIndex.backend.update_aliases!(suffix: 'v1') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        ).with_message(/\[#{cluster.index_prefix}_dummies_v1\] missing/)
        expect(DummiesIndex.backend.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect(DummiesIndex.backend.update_aliases!(suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create_index(alias: true, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create_index(alias: false, suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v2")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v3")).to eq(true)
        expect(client.indices.get_alias(index: "#{cluster.index_prefix}_dummies")).to eq(
          "#{cluster.index_prefix}_dummies_v2" => {
            'aliases' => {
              "#{cluster.index_prefix}_dummies" => {},
            },
          },
        )
        expect(DummiesIndex.backend.update_aliases!(suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.get_alias(index: "#{cluster.index_prefix}_dummies")).to eq(
          "#{cluster.index_prefix}_dummies_v3" => {
            'aliases' => {
              "#{cluster.index_prefix}_dummies" => {},
            },
          },
        )
      end
    end
  end
end
