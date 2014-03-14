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
      def path_to_hash(path, value)
        arr = path.split("%") #["development", "db", "storage", "adapter"]
        hashes = Array.new(arr.length) #[{}, {}]
        hashes.fill(Hash.new)

        arr.reverse.each_with_index do |item, index|
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
      def update_settings(new_data,config)
        raise ArgumentError, "new_data must be a hash!" unless new_data.kind_of? Hash
        raise StandardError, "Yaml file with settings is not defined!" unless config.is_a? String
        begin
          File.open(config, "w"){|f|f.write new_data.to_yaml}
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
      config = File.expand_path(File.join(File.dirname(__FILE__), '../config/config.yaml'))
      @settings = YAML.load_file(config)[ENV['MAPPER_ENV']]
      erb :settings
    end
    post '/settings/update' do
      # прислати тільки ті значення які змінились
      config = File.expand_path(File.join(File.dirname(__FILE__), '../config/config.yaml'))
      @settings = YAML.load_file(config)#[ENV['MAPPER_ENV']]
  
      params.each do |key, value|
        p "Path: #{key} - value#{value}"
        new_data = path_to_hash(key, value)
        p new_data
        @settings = @settings.deep_merge(new_data)
      end
      p "======================================="
      p @settings
      update_settings(@settings, config)
      redirect to '/settings'
      #p @settings
      # пробігаємось по всіх значеннях і в циклі зєднюємо з хешом 
      # Записуємо назад або пересилаємо
      body {@settings.to_s}
      # 1. to hash
      # 2. send to mapper
      #send("rabbit.mapper", settings, "/settings")
    end
  end
end

