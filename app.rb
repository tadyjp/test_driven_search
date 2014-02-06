require 'sinatra/base'

require_relative 'models/restaurant'
require_relative 'models/category'
require_relative 'models/pref'

class Server < Sinatra::Base
  get '/' do

    @query = params[:q] if params[:q] && params[:q] != ''
    if @query
      res = Restaurant.search(@query)
      ids = res[:ids]
      @restaurants = Restaurant.where('id in (?)', ids).limit(100)
      @took = res[:response]['took']
      @count = res[:response]['hits']['total']
      @pref_id_facets = res[:response]['facets']['pref_id_facet']['terms']
      @category_ids_facets = res[:response]['facets']['category_ids_facet']['terms']
    else
      @restaurants = Restaurant.all.limit(100)
    end

    erb :index
  end
end
