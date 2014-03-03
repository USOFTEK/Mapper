require 'em-synchrony'
require 'em-synchrony/mysql2'
require 'em-synchrony/fiber_iterator'
require 'amqp'
require 'fiber'
require 'yaml'
require 'logging'
require 'net/http'

require_relative 'SearchWorker'
require_relative '../app/models/Product'
require_relative '../app/models/async/NonBlockingDB'
require_relative '../app/models/async/StorageItem'
require_relative '../app/models/async/StoragePrice'
require_relative '../app/models/async/StorageComparison'
require_relative '../app/models/async/ShopItem'
require_relative 'WebServer'

module Mapper
  class Base
    attr_accessor :working_dir
    attr_reader :storage_comparison, :storage_item
    def initialize
      @options = {:dir=>"../prices", :env => 'development'}
      config, dictionary = "../config/config.yaml", "../config/dictionary.yaml"
      begin
        @config = YAML.load_file(check_filename config)[@options[:env]]
        @dictionary = YAML.load_file(check_filename dictionary)
      rescue Errno::ENOENT => e
        p e.message
      end
      @working_dir = File.dirname(__FILE__)
      register_async_models
      set_logger
      @search_worker = SearchWorker.new @config["search"], @dictionary["search"] # <= пошук
      Thread.abort_on_exception=true
    end
    def set_output output
      @output = output
    end
    def check_filename filename
      raise ArgumentError 'filename is not defined' if filename.nil?
      (File.exists?(filename)) ? filename : File.join(@working_dir,filename)
    end
    def run
      @output ||= STDOUT
      #begin
      @output.print "Run, Forest, run!"
      #rescue
      #  @output = STDOUT
      #  retry
      #end
      EM.synchrony do
        @logger.debug "Mapper has been started #{Time.now}"
        AMQP.start do |connection|
          @logger.debug "AMQP started #{Time.now}"
          channel = AMQP::Channel.new connection
          queue = channel.queue(@config["broker"]["queue_name"], :auto_delete => true)
          #exchange = channel.direct("amqp.default.exchange")
          #queue.bind(exchange)
          queue.subscribe do |payload|
            @logger.debug "Received message #{payload}"
            connection.close {EM.stop} if payload == "stop"
            Fiber.new{PriceManager.new.load_prices}.resume if payload == "start"
            Fiber.new {match}.resume if payload == 'match'
            EM.defer {start_webserver} if payload == 'start_webserver'
            EM.defer {start_search_server} if payload == 'start_solr'
            EM.defer {stop_search_server} if payload == 'stop_solr'
            EM.defer {add_db_to_search_index} if payload == 'index'
            EM.defer {setup_storage} if payload == 'setup_storage'
            proc{ queue.unsubscribe; queue.delete;connection.close{EM.stop} }.call == 'test'
          end
        end
      end
    end
    def start_webserver
      stop_webserver
      WebServer.run!
    end
    def stop_webserver
      system "fuser -k 4567/tcp"
    end
    def setup_storage
      StorageBase.setup
    end
    def add_db_to_search_index
      @search_worker.index
    end
    def register_async_models
      @price = StoragePrice.new "storage"
      @shop_item = ShopItem.new "shop"
      @storage_item = StorageItem.new "storage"
      @storage_comparison = StorageComparison.new "storage"
    end
    def stop_search_server
      system "fuser -k 8983/tcp"
    end
    def start_search_server
      begin
        stop_search_server
        FileUtils.cd '../solr/example' do
          command = ["java"]
          command << "-Dsolr.solr.home=./example-DIH/solr/"
          command << "-jar"
          command << "start.jar"
          pid = spawn(*command,:in=>'/dev/null', :out => '/dev/null', :err => '/dev/null')
          p "Solr is running on #{pid}"
        end
      rescue => e
        p e
      end
    end
    # співставлення
    def match
      EM::Synchrony::FiberIterator.new(@storage_item.all, @config["concurrency"]["iterator_size"]).each do |product|
        begin
          (product["code"].empty?) ? storage_item_model =  product["article"] : storage_item_model =  product["code"]
          response = @search_worker.find({
              :title => product["title"],
              :model => storage_item_model    
          })
          if response[:count] > 0
            shop_item = response.docs[0] # <= беремо тільки перший знайдений товар
            shop_product_id = shop_item["id"].to_i
            price_product_id = product["id"]
            p shop_item
            linked = check_models(shop_item["model"], storage_item_model) || check_titles(shop_item["title"], product["title"])
            p "Linked: #{linked}"
            @storage_comparison.link(price_product_id, shop_product_id, linked).errback {|error|p error}
          end
        rescue => e
          p e
        end
      end
    end
    #TODO: вдосконалити
    def check_titles(shop_item_title, storage_item_title)
      shop_item_title.downcase!
      storage_item_title.downcase!
      if (shop_item_title.size == storage_item_title.size) 
        shop_item_title == storage_item_title
      elsif shop_item_title.size > storage_item_title.size
        shop_item_title.include? storage_item_title
      else
        storage_item_title.include? shop_item_title
      end
    end
    #порівняння моделей товарів
    def check_models(shop_item_model, storage_item_model)
      return false if (shop_item_model.nil? || shop_item_model.empty? || shop_item_model == "NULL") || (storage_item_model.empty? || storage_item_model.nil? || storage_item_model == "NULL")
      p "#{shop_item_model} - #{storage_item_model}"
      begin
        shop_item_model["-"] = "" if shop_item_model.index "-"
        storage_item_model["-"] = "" if storage_item_model.index "-"
      rescue => e
        p e
      end
      shop_item_model.downcase == storage_item_model.downcase
    end
    def set_logger
      @logger = Logging.logger[self.class.name]
      filename = '../log/development.log'
      @logger.add_appenders(
        Logging.appenders.stdout,
        Logging.appenders.file(check_filename filename)
      )
      @logger.level = :debug
    end
  end
end
  
require_relative 'PriceManager'
require_relative 'PriceReader'

#mapper = Mapper::Base.new
#mapper.run


