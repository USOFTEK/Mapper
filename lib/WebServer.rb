require 'sinatra/base'
require 'sinatra/async'

class WebServer < Sinatra::Base
  set :server, :thin
  register Sinatra::Async
  configure do
    set :threaded, true
    set :root, "../app/" # <= TODO: for gem location
    set :public_folder, Proc.new { File.join(root, "assets") }
  end
  get '/' do
    @title = "Home"
    erb :index
  end
  aget '/send/:command' do
    command = params[:command]
    p command
    EM.run do
      AMQP.connect do |connection|
        puts "Send message: #{command}"
        channel = AMQP::Channel.new connection
        queue = channel.queue("rabbit.mapper", :auto_delete => true)
        exchange = channel.default_exchange
        exchange.publish(command, :routing_key => queue.name)
        EventMachine.add_timer(1) {
          p "AMQP Broker says bye!"
          connection.close
          redirect to '/'
          }
      end
    end
  end
  aget '/delay/:n' do |n|
    EM.add_timer(n.to_i) { body { "delayed for #{n} seconds" } }
  end
  get '/link' do 
    @title = "Таблиця порівняння товарів"
    @products = Product.get_all
    erb :link
  end
  post '/link/:id/:linked' do
    id = params[:id].to_i
    linked = params[:linked].to_i
    p Comparison.update(id, {:linked => linked}) unless linked.nil? or id.nil?
  end
end

