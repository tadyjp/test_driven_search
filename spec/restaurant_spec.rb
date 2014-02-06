require_relative '../models/restaurant'

class Restaurant
  def self.es_index_name
    'livedoor-gourmet-test'
  end
end

describe 'Restaurant' do

  before :all do
    Restaurant.es_delete_index
    Restaurant.es_create_index # in_memory: true

    Restaurant.es_index_doc id: 1001, name: 'らーめん田中', address: '東京都千代田区', pref_id: 13
    Restaurant.es_index_doc id: 1002, name: '新宿ラーメン', address: '神奈川県横浜', pref_id: 14
    Restaurant.es_index_doc id: 1003, name: 'カフェ Jack', address: '東京都港区区', pref_id: 13
    Restaurant.es_index_doc id: 1004, name: 'ラーメン東京一番', address: '東京都新宿区', pref_id: 13
    Restaurant.es_index_doc id: 1005, name: 'カフェ Taro', address: '京都府左京区', pref_id: 26
    Restaurant.es_index_doc id: 1006, name: 'ラーメン 三郎', address: '東京都大田区', pref_id: 13

    Restaurant.es_refresh_index
  end

  describe 'query' do
    it 'ラーメン' do
      expect(Restaurant.search('ラーメン')[:ids]).to include(1002)
      expect(Restaurant.search('ラーメン')[:ids]).to include(1004)
      expect(Restaurant.search('ラーメン')[:ids]).to include(1006)
    end

    it 'ラーメン東京一番' do
      expect(Restaurant.search('ラーメン東京一番')[:ids]).to include(1004)
    end

    it '新宿ラーメン' do
      expect(Restaurant.search('新宿ラーメン')[:ids]).to include(1002)
    end

    it 'jack - 大文字小文字' do
      expect(Restaurant.search('jack')[:ids]).to include(1003)
    end
  end

  describe 'boost - 住所優先' do
    it do
      ids = Restaurant.search('京都')[:ids]
      expect(ids).to include(1006)
      expect(ids).to include(1005)
      expect(ids.index(1006)).to be > ids.index(1005)
    end
  end

  describe 'facets' do
    it 'ラーメン > 東京*2, 神奈川*1' do
      facet_res = Restaurant.search('ラーメン')[:response]['facets']['pref_id_facet']['terms']
      expect(facet_res[0]['term']).to eq(13)
      expect(facet_res[0]['count']).to eq(2)
      expect(facet_res[1]['term']).to eq(14)
      expect(facet_res[1]['count']).to eq(1)
    end
  end

  describe 'suggest' do
    it 'ラメーン > ラーメン' do
      expect(Restaurant.search('ラメーン')[:suggests][0]['text']).to eq('ラーメン')
    end
  end

  describe 'completion' do
    it 'ラー > ラーメン' do
      expect(Restaurant.completion('ラー')[0]['text']).to include('ラー')
    end
  end
end
