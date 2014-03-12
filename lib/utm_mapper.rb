require 'em-synchrony'
require 'em-synchrony/mysql2'
require 'em-synchrony/fiber_iterator'
require 'amqp'
require 'fiber'
require 'yaml'
require 'logging'
require 'digest'

require_relative 'SearchWorker'
require_relative File.expand_path(File.join(File.dirname(__FILE__), '../app/models/Product'))
require_relative File.expand_path(File.join(File.dirname(__FILE__),'../app/models/async/NonBlockingDB'))
require_relative File.expand_path(File.join(File.dirname(__FILE__),'../app/models/async/StorageItem'))
require_relative File.expand_path(File.join(File.dirname(__FILE__),'../app/models/async/StoragePrice'))
require_relative File.expand_path(File.join(File.dirname(__FILE__),'../app/models/async/StorageComparison'))
require_relative File.expand_path(File.join(File.dirname(__FILE__),'../app/models/async/ShopItem'))
require_relative 'Webserver'

module Mapper
  class Base
    attr_reader :search_worker
    def initialize
      raise StandardError, "Mapper env is not defined!" if ENV['MAPPER_ENV'].nil?
      @options = {:env => ENV['MAPPER_ENV']}
      @working_dir = File.dirname(__FILE__)
      p "working dir #{@working_dir}"
      config_dir = File.expand_path(File.join(File.dirname(__FILE__), '../config'))
      config, dictionary = "#{config_dir}/config.yaml", "#{config_dir}/dictionary.yaml"
      begin
        @config = YAML.load_file(config)[@options[:env]]
        @dictionary = YAML.load_file(dictionary)
      rescue Errno::ENOENT => e
        p e.message
      end
      Thread.abort_on_exception=true
      @output ||= STDOUT
      set_logger
      define_workers
    end
    
    public
    #runs reactor and starts amqp broker for receveing messages
    def run
      @output.print "Run, Forest, run!"
      
      EM.synchrony do
        print "Mapper has been started #{Time.now}"
        AMQP.start do |connection|
          print "AMQP started #{Time.now}"
          channel = AMQP::Channel.new connection
          queue = channel.queue(@config["broker"]["queue_name"], :auto_delete => true)
          queue.subscribe do |payload|
            print "Received message #{payload}"
            connection.close {EM.stop} if payload == "stop"
            Fiber.new{start}.resume if payload == "start"
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
    # parse price-lists
    def start
      Fiber.new{PriceManager.new.load_prices}.resume
    end
    # web-interface for price managment on localhost:4567
    def start_webserver
      stop_webserver
      Webserver.run!
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
    def stop_search_server
      system "fuser -k 8983/tcp"
    end
    def start_search_server
      begin
        return false if @search_worker.server_running?
        stop_search_server
        FileUtils.cd '../solr/example' do
          command = ["java"]
          command << "-Dsolr.solr.home=./example-DIH/solr/"
          command << "-jar"
          command << "start.jar"
          pid = spawn(*command,:in=>'/dev/null',:err => :out)
          p "Solr is running on #{pid}"
          return true
        end
      rescue => e
        p e
      end
    end
    # match products from parsed price-lists and products from online shop
    def match
      EM::Synchrony::FiberIterator.new(@storage_item.all, @config["concurrency"]["iterator_size"]).each do |product, iter|
        link(product)
      end
    end
    
    def print message
      @logger.debug message
      @output.print message
    end
    def set_logger
      logger = Logging.logger[self.class.name]
      filename = File.expand_path(File.join(File.dirname(__FILE__),"../log/#{@options[:env]}.log"))
      logger.add_appenders(
        Logging.appenders.stdout,
        Logging.appenders.file(filename)
      )
      logger.level = :debug
      @logger = logger
    end
    def set_output output; @output = output; end
    
    private
    
    def define_workers
      @price = StoragePrice.new "storage"
      @shop_item = ShopItem.new "shop"
      @storage_item = StorageItem.new "storage"
      @storage_comparison = StorageComparison.new "storage"
      @search_worker = SearchWorker.new @config["search"], @dictionary["search"] # <= пошук
    end
    def link(product)
      begin
        (product["code"].empty?) ? storage_item_model =  product["article"] : storage_item_model =  product["code"]
        response = @search_worker.find({:title => product["title"],:model => storage_item_model})
      
        if response[:count] > 0
          shop_item = response.docs[0] # <= беремо тільки перший знайдений товар
          shop_product_id = shop_item["id"].to_i
          price_product_id = product["id"]
          p shop_item
          linked = check_models(shop_item["model"], storage_item_model) || check_titles(shop_item["title"], product["title"])
          p "Linked: #{linked}"
          @storage_comparison.link(price_product_id, shop_product_id, linked).errback {|error|p error}
        else
          p "Product: #{product["title"]} has no results :((" 
        end
      rescue => e
        p e
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
    # compare two models from storage and shop databases
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
    def update_settings(new_data, *config)
      raise ArgumentError, "new_data must be a hash!" unless new_data.kind_of? Hash
      begin
        if config
          settings = YAML.load_file(config)
        elsif @config
          settings = @config
        else
          raise StandardError, "Yaml file with settings is not defined!"
        end
        File.open(settings, "w"){|f|f.write settings.merge(new_data).to_yaml}
      rescue => e
        p e
      end
    end
  end
end
  
require_relative 'PriceManager'
require_relative 'PriceReader'
