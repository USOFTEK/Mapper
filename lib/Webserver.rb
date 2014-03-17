require 'sinatra/base'
require 'sinatra/async'
require 'active_support'
require_relative File.expand_path(File.join(File.dirname(__FILE__),'../app/models/Product'))
module Mapper
  class Webserver < Sinatra::Base
    set :server, :thin
    register Sinatra::Async
    configure do
      set :threaded, true
      set :root, File.expand_path(File.join(File.dirname(__FILE__),"../app/")) # <= TODO: for gem location
      set :public_folder, Proc.new { File.join(root, "assets") }
      set :config,  File.expand_path(File.join(File.dirname(__FILE__), '../config/config.yaml'))
      set :split_sign, "%"
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
      def merge(settings, params)
        params.each do |key, value|
          new_data = path_to_hash(key, value)
          settings = settings.deep_merge(new_data)
        end
        p settings
        settings
      end
      def path_to_hash(path, value)
        arr = path.split(settings.split_sign) #["development", "db", "storage", "adapter"]
        hashes = Array.new(arr.length) #[{}, {}]
        hashes.fill(Hash.new)

        arr.each_with_index do |item, index|
          if index == 0
            hashes[index][item] = value
          else
            hashes[index] = ""
            hashes[index] = {}
            hashes[index][item] = hashes[index - 1]
          end
        end
        hashes.last
      end
      def update_settings(new_data)
        raise ArgumentError, "new_data must be a hash!" unless new_data.kind_of? Hash
        raise StandardError, "Yaml file with settings is not defined!" unless settings.config.is_a? String
        begin
          File.open(settings.config, "w"){|f|f.write new_data.to_yaml}
        rescue => e
          p e
        end
      end
    end
    get '/hello-world' do
      body {
        "Url: #{request.url} \n Fullpath: #{request.fullpath} \n
        Path-info: #{request.path_info}"
      }
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
      p settings.config
      @env = ENV['MAPPER_ENV']
      @action = "/settings/update"
      @method = "POST"
      @split_sign = settings.split_sign
      @options = YAML.load_file(settings.config)[@env]
      
      erb :options
    end
    post '/settings/update' do
      redirect to '/settings' if params.empty?
      options = YAML.load_file(settings.config)
      new_settings = merge(options, params)
      update_settings(new_settings)
      
      redirect to '/settings'
    end
  end
end

