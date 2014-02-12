require 'sinatra/base'

class WebServer < Sinatra::Base
 configure do
    set :threaded, true
  end
  get '/' do 
    @title = "Home"
    @products = Product.get_all
    erb :index
  end
  post '/link/:id/:linked' do
    id = params[:id].to_i
    linked = params[:linked].to_i
    p Comparison.update(id, {:linked => linked}) unless linked.nil? or id.nil?
  end
end

