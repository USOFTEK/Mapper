require 'sinatra/base'
require 'sinatra/async'
require_relative File.expand_path(File.join(File.dirname(__FILE__),'../app/models/Product'))
module Mapper
  class Webserver < Sinatra::Base
    set :server, :thin
    register Sinatra::Async
    configure do
      set :threaded, true
      set :root, File.expand_path(File.join(File.dirname(__FILE__),"../app/")) # <= TODO: for gem location
      set :public_folder, Proc.new { File.join(root, "assets") }
    end
    helpers do
      def send(where, what, *redirect)
        EM.run do
        AMQP.connect do |connection|
          puts "Send message: #{what}"
          channel = AMQP::Channel.new connection
          queue = channel.queue(where, :auto_delete => true)
          exchange = channel.default_exchange
          exchange.publish(what, :routing_key => queue.name)
          EM.add_timer(1) {
            p "AMQP Broker says bye!"
            connection.close
            redirect to(redirect) if redirect
          }
        end
      end
      end
    end
    get '/hello-world' do
      request.path_info   # => '/hello-world'
      request.fullpath    # => '/hello-world?foo=bar'
      request.url         # => 'http://example.com/hello-world?foo=bar'
    end
    get '/' do
      @title = "Home"
      erb :index
    end
    aget '/send/:command' do
      send("rabbit.mapper", params[:command], "/")
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
    get '/settings' do
      config = File.expand_path(File.join(File.dirname(__FILE__), '../config/config.yaml'))
      @settings = YAML.load_file(config)[ENV['MAPPER_ENV']]
      erb :settings
    end
    post '/settings/update/:settings' do
      settings = params[:settings]
      p settings
      # 1. to hash
      # 2. send to mapper
      send("rabbit.mapper", settings, "/settings")
    end
  end
end

