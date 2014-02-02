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

    Restaurant.es_index_doc id: 1001, name: 'らーめん田中', address: '東京都港区区'
    Restaurant.es_index_doc id: 1002, name: '新宿ラーメン', address: '東京都千代田区区'
    Restaurant.es_index_doc id: 1003, name: 'カフェ Jack', address: '神奈川県横浜'
    Restaurant.es_index_doc id: 1004, name: 'ラーメン東京一番', address: '東京都新宿区'
    Restaurant.es_index_doc id: 1005, name: 'カフェ Taro', address: '京都府左京区'
    Restaurant.es_index_doc id: 1006, name: 'カフェ Taro', address: '東京都大田区'

    Restaurant.es_refresh_index
  end

  describe 'query' do
    it { expect(Restaurant.search('ラーメン')).to include(1002) }
    it { expect(Restaurant.search('ラーメン')).not_to include(1001) }
  end

  describe 'boost' do
    it do
      expect(Restaurant.search('京都')).to include(1005)
    end

    it do
      expect(Restaurant.search('京都')).to include(1006)
    end

    it do
      ids = Restaurant.search('京都')
      expect(ids.index(1006)).to be > ids.index(1005)
    end

  end

  # describe 'boost' do
  #   res_ids = TestDrivenSearch.search_by_body('ruby').map{|i| i['_source']['id']}
  #   it { expect(res_ids).to include(1001) }
  #   it { expect(res_ids).not_to include(1002) }
  # end

end
