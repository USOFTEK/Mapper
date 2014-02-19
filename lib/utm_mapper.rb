require 'em-synchrony'
require 'em-synchrony/mysql2'
require 'em-synchrony/fiber_iterator'
require 'amqp'
require 'fiber'
require 'yaml'
require 'logging'

require_relative 'SearchWorker'
require_relative 'models/Product'
require_relative 'models/async/NonBlockingDB'
require_relative 'models/async/StorageItem'
require_relative 'models/async/StoragePrice'
require_relative 'models/async/StorageComparison'
require_relative 'models/async/ShopItem'
require_relative 'WebServer'

module Mapper
  class Base
    attr_accessor :working_dir
    def initialize
      @options = {:dir=>"prices/test", :env => 'development'}
      config, dictionary = "config.yaml", "dictionary.yaml"
      config = File.join(File.dirname(__FILE__),config) unless File.exists? config
      dictionary = File.join(File.dirname(__FILE__),dictionary) unless File.exists? dictionary
      @config = YAML.load_file(config)[@options[:env]]
      @dictionary = YAML.load_file(dictionary)
      @working_dir = Dir.pwd
      register_async_models
      set_logger
      @search_worker = SearchWorker.new @config["search"], @dictionary["search"] # <= пошук
      Thread.abort_on_exception=true
    end
    def run
      EM.synchrony do
        @logger.debug "Mapper has been started #{Time.now}"
        #Fiber.new {PriceManager.new.load_prices}.resume
        AMQP.start do |connection|
          @logger.debug "AMQP started #{Time.now}"
          channel = AMQP::Channel.new connection
          queue = channel.queue(@config["broker"]["queue_name"], :auto_delete => true)
          #exchange = channel.direct("default")
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
          end
        end
      end
    end
    def start_webserver
      WebServer.run!
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
      FileUtils.cd(working_dir) do
        if File.exist?("solr_pid")
          begin
            pid = IO.readlines("solr_pid")[0].to_i
            Process.kill(0, pid)
          rescue => e 
            STDERR.puts("Removing PID file at #{working_dir}")
            FileUtils.rm "solr_pid"
            p e
          end
        end
      end
    end
    def start_search_server
      begin
        #exec "fuser", "-k", "8983/tcp"
        stop_search_server
        pid = fork do
          Process.setsid
          STDIN.reopen('/dev/null')
          STDOUT.reopen('/dev/null')
          STDERR.reopen(STDOUT)
          FileUtils.cd 'solr/example' do
            command = ["java"]
            command << "-Dsolr.solr.home=./example-DIH/solr/"
            command << "-jar"
            command << "start.jar"
            exec(*command)
          end
        end
        File.open("solr_pid", "w") {|file| file << pid}
        p "Solr is running on #{pid}"
      rescue => e
        p e
      end
    end
    # співставлення
    def match
       
      EM::Synchrony::FiberIterator.new(@storage_item.all, @config["concurrency"]["iterator_size"]).each do |product, iter|
        begin
          (product["code"].empty?) ? storage_item_model =  product["article"] : storage_item_model =  product["code"]
          response = @search_worker.find({
              :title => product["title"],
              :model => storage_item_model}
          )
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
      @logger.add_appenders(
        Logging.appenders.stdout,
        Logging.appenders.file('log/development.log')
      )
      @logger.level = :debug
    end
  end
end
  
require_relative 'PriceManager'
require_relative 'PriceReader'

mapper = Mapper::Base.new
mapper.run


