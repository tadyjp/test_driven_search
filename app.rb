require 'sinatra/base'

require_relative 'models/restaurant'

class Server < Sinatra::Base
  get '/' do
    erb :index
  end
end
