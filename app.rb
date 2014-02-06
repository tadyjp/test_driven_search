require 'json'
require 'sinatra/base'

require_relative 'models/restaurant'
require_relative 'models/category'
require_relative 'models/pref'

class Server < Sinatra::Base
  get '/' do

    @query = params[:q] if params[:q] && params[:q] != ''
    if @query
      # ES検索
      res = Restaurant.search(@query)
      ids = res[:ids]

      # DBから取得
      sanitized_query = ActiveRecord::Base.send(:sanitize_sql_array, ['field(id, ?)', ids])
      @restaurants = Restaurant.where(id: ids).order(sanitized_query)

      # 検索時間
      @took = res[:response]['took']

      # 検索Hit件数
      @count = res[:response]['hits']['total']

      # もしかして
      @did_you_mean = res[:suggests]

      # 都道府県Facet
      @pref_id_facets = res[:response]['facets']['pref_id_facet']['terms']

      # カテゴリFacet
      @category_ids_facets = res[:response]['facets']['category_ids_facet']['terms']
    else

      @restaurants = Restaurant.all.limit(100)
    end

    erb :index
  end

  get '/complete.json' do

    Restaurant.completion(params[:q]).map{ |term|
      {
        value: term['text'],
        tokens: [term['text']]
      }
    }.to_json
  end
end
