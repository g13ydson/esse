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
          DummiesIndex.backend.create!
          expect(DummiesIndex.backend.exist?).to eq(true)
        end
      end
    end
  end

  describe '.create!' do
    specify do
      es_client do
        expect(DummiesIndex.backend.create['acknowledged']).to eq(true)
      end
    end

    it 'creates a suffixed index and its alias' do
      es_client do |client, conf|
        allow(Esse).to receive(:timestamp).and_return('2020')
        expect(DummiesIndex.backend.create!['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create!(suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(true)
        expect { DummiesIndex.backend.create!(suffix: 'v1') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::BadRequest,
        ).with_message(/\[#{conf.index_prefix}_dummies_v1\] already exists/)
        expect(DummiesIndex.backend.indices).to match_array(
          [
            "#{conf.index_prefix}_dummies_2020",
            "#{conf.index_prefix}_dummies_v1"
          ],
        )
        expect(DummiesIndex.backend.aliases).to match_array([
                                                              "#{conf.index_prefix}_dummies"
                                                            ])
      end
    end

    it 'creates a suffixed index without alias' do
      es_client do |client, conf|
        allow(Esse).to receive(:timestamp).and_return('2020')
        expect(DummiesIndex.backend.create!(alias: false)['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create!(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(true)
        expect { DummiesIndex.backend.create!(alias: false, suffix: 'v1') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::BadRequest,
        ).with_message(/\[#{conf.index_prefix}_dummies_v1\] already exists/)
        expect(DummiesIndex.backend.indices).to match_array([])
        expect(DummiesIndex.backend.aliases).to eq([])
      end
    end
  end

  describe '.create' do
    specify do
      es_client do
        expect(DummiesIndex.backend.create['acknowledged']).to eq(true)
      end
    end

    it 'creates a suffixed index and its alias' do
      es_client do |client, conf|
        allow(Esse).to receive(:timestamp).and_return('2020')
        expect(DummiesIndex.backend.create['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create(suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(true)
        expect(DummiesIndex.backend.create(suffix: 'v1')).to eq(false)
        expect(DummiesIndex.backend.create(suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.indices).to match_array(
          [
            "#{conf.index_prefix}_dummies_2020",
            "#{conf.index_prefix}_dummies_v1",
            "#{conf.index_prefix}_dummies_v2"
          ],
        )
        expect(DummiesIndex.backend.aliases).to match_array([
                                                              "#{conf.index_prefix}_dummies"
                                                            ])
      end
    end

    it 'creates a suffixed index without alias' do
      es_client do |client, conf|
        allow(Esse).to receive(:timestamp).and_return('2020')
        expect(DummiesIndex.backend.create(alias: false)['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(true)
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v1')).to eq(false)
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.indices).to match_array([])
        expect(DummiesIndex.backend.aliases).to eq([])
      end
    end
  end

  describe '.delete' do
    specify do
      es_client do |_client, _conf|
        expect(DummiesIndex.backend.delete(suffix: nil)).to eq(false)
      end
    end

    specify do
      es_client do |_client, _conf|
        expect(DummiesIndex.backend.delete(suffix: 'v1')).to eq(false)
      end
    end

    specify do
      es_client do |_client, _conf|
        expect(DummiesIndex.backend.create(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.delete(suffix: 'v1')['acknowledged']).to eq(true)
      end
    end

    specify do
      es_client do |client, conf|
        expect(DummiesIndex.backend.create(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.delete(suffix: nil)['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(false)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v2")).to eq(true)
      end
    end
  end

  describe '.delete!' do
    specify do
      es_client do |_client, _conf|
        expect { DummiesIndex.backend.delete!(suffix: nil) }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
      end
    end

    specify do
      es_client do |_client, _conf|
        expect { DummiesIndex.backend.delete!(suffix: 'v1') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
      end
    end

    specify do
      es_client do |_client, _conf|
        expect(DummiesIndex.backend.create(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.delete!(suffix: 'v1')['acknowledged']).to eq(true)
      end
    end

    specify do
      es_client do |client, conf|
        expect(DummiesIndex.backend.create(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.delete!(suffix: nil)['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(false)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v2")).to eq(true)
      end
    end
  end

  describe '.update_aliases' do
    specify do
      es_client do |client, conf|
        expect(DummiesIndex.backend.update_aliases(suffix: 'v1')).to eq(false)
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(true)
        expect(DummiesIndex.backend.update_aliases(suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(true)
      end
    end

    specify do
      es_client do |client, conf|
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create(alias: true, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v2")).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v3")).to eq(true)
        expect(client.indices.get_alias(index: "#{conf.index_prefix}_dummies")).to eq(
          "#{conf.index_prefix}_dummies_v2" => {
            'aliases' => {
              "#{conf.index_prefix}_dummies" => {},
            },
          },
        )
        expect(DummiesIndex.backend.update_aliases(suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.get_alias(index: "#{conf.index_prefix}_dummies")).to eq(
          "#{conf.index_prefix}_dummies_v3" => {
            'aliases' => {
              "#{conf.index_prefix}_dummies" => {},
            },
          },
        )
      end
    end
  end

  describe '.update_aliases!' do
    specify do
      es_client do |client, conf|
        expect { DummiesIndex.backend.update_aliases!(suffix: 'v1') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        ).with_message(/\[#{conf.index_prefix}_dummies_v1\] missing/)
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(true)
        expect(DummiesIndex.backend.update_aliases!(suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(true)
      end
    end

    specify do
      es_client do |client, conf|
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create(alias: true, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create(alias: false, suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v1")).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v2")).to eq(true)
        expect(client.indices.exists(index: "#{conf.index_prefix}_dummies_v3")).to eq(true)
        expect(client.indices.get_alias(index: "#{conf.index_prefix}_dummies")).to eq(
          "#{conf.index_prefix}_dummies_v2" => {
            'aliases' => {
              "#{conf.index_prefix}_dummies" => {},
            },
          },
        )
        expect(DummiesIndex.backend.update_aliases!(suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.get_alias(index: "#{conf.index_prefix}_dummies")).to eq(
          "#{conf.index_prefix}_dummies_v3" => {
            'aliases' => {
              "#{conf.index_prefix}_dummies" => {},
            },
          },
        )
      end
    end
  end
end