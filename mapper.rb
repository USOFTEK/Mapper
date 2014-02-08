module Mapper
  require_relative 'PriceReader'
  require_relative 'models/Prices'
  require_relative 'models/Products'
  require_relative 'models/ProductComparisons'
  require_relative 'lib/Search'
  require 'benchmark'
  require 'em-synchrony'
  require 'em-synchrony/mysql2'
  require 'em-synchrony/fiber_iterator'
  require 'amqp'
  require 'fiber'
  require 'yaml'

  # responsible for loading price-lists and comparing them
  class PriceManager
    attr_reader :prices
    def initialize(*options)
      @prices = Array.new # <= array of Price objects
      default_options = {:dir=>"prices", :env => 'production'}
      (options.empty?) ? @options = default_options : @options = options[0] # <= default value
      @config = YAML.load_file('config.yaml')[@options[:env]]
      #p @config
      #exit
      set_db_client
      get_prices_from_dir
      @search_worker = SearchWorker.new @config["search"] # <= пошук
      Thread.abort_on_exception=true
    end
    def start
      p "Mapper has been started"
      EM.synchrony do
        AMQP.start do |connection|
          puts "AMQP started"
          channel = AMQP::Channel.new connection
          queue = channel.queue(@config["broker"]["queue_name"], :auto_delete => true)
          exchange = channel.direct("")
          #queue.bind(exchange)
          queue.subscribe do |payload|
            puts "Received message #{payload}"
            connection.close {EM.stop} if payload == "stop"
            Fiber.new {load_prices}.resume if payload == "start"
            Fiber.new {match}.resume if payload == 'match'
            EM.defer {@search_worker.index} if payload == 'index'
          end
        end
        match
      end
    end
    #зчитує файли з потрібною директорії
    def get_prices_from_dir *dir
      (dir.empty?) ? dir = @options[:dir] : dir = dir[0]
      Dir.chdir(dir);
      extensions = @config["extensions"].join(",")
      @filenames = Dir.glob("*.{#{extensions}}")
    end
    # приймає масив прайсів
    def load_prices(*params)
      (params.empty?) ? filenames = @filenames : filenames = params[0]
      raise ArgumentError, 'must be array of files #{filenames.kind_of?}' unless filenames.kind_of?(Array) 
      @price_count = filenames.size
      @counter = 0
      EM::Synchrony::FiberIterator.new(filenames, @config["concurrency"]["iterator_size"]).map do |filename, iter|
        #TODO: перевіряти розмір або хеш файлу, якщо змінився проводити парсинг ще раз
        unless Price.find_by_price(filename) # <= # перевірка імені прайсу
          p "Filename now is procesed: #{filename}"
          operation = proc {PriceReader.new(filename).parse }
          callback = proc do |data|
            EM.defer(proc { insert_data(data, filename)})
          end
          EM.defer(operation, callback)
        else
          p "Price #{filename} already exists in database!"
        end
      end
      p "Finished"
    end
    def set_db_client
      @db = EventMachine::Synchrony::ConnectionPool.new(:size => @config["concurrency"]["pool_size"]) do
        Mysql2::EM::Client.new(@config["db"])
      end
    end
    # занесення прайсів у базу
    def escape_row(row)
      @db.escape row || "NULL"
    end
    # TODO: запити до бази винести в окремий клас
    def insert_data(data, filename)
      insertion = @db.aquery "INSERT INTO `prices` (`price`) VALUES ('#{filename}')"
      insertion.callback do 
        price_id = @db.last_id
        values = []
        query_string =  "INSERT INTO `products` (`code`, `title`, `article`, `price_id`) VALUES "
        data[:results].each do |row|
          values << "('#{escape_row row[:code]}','#{escape_row row[:title]}','#{escape_row row[:article]}','#{price_id}')"
        end
        query = query_string + values.join(",")
        @db.aquery(query).callback {
          @counter += 1
          p "#{filename} successfully inserted!"
          p "Procesed #{@counter} from #{@price_count}"
          insertion_finished if @counter == @price_count
        }
      end
    end
    def insertion_finished
      p "Insertion has been finished successfully!"
      p "Do you want to start matching products? Type 'Y' or 'N'"
      command = gets.chomp.downcase
      match if command == 'y'
      EM.stop if command == 'n'
    end
    # співставлення
    def match
      index = 0
      start = 0
      finish = 50
      EM::Synchrony::FiberIterator.new(Product.all[start..finish], @config["concurrency"]["iterator_size"]).each do |product, iter|
        begin
          p response = @search_worker.find({
              :title => product["title"],
              :model => product["code"]}
          )
          #response = {:count => 5, :results => [{"id"=> 34}]}
          #TODO: що робити з тими запитами, які не мають взагалі співпадінь?
          if response[:count] > 0
            #p response
            #shop_product_id = response[:results][0]["id"].to_i
            #price_product_id = product["id"]
            #p response[:results][0]
            #TODO: precision = response[:precision] визначення точності результату пошуку
            #ProductComparison.link(price_product_id, shop_product_id)
          end
        rescue => e
          p e
        else
          index += 1
          EM.stop if index == finish - start
        end
      end
    end
  end
end
Mapper::PriceManager.new({:dir=>"prices/test", :env => 'development'}).start
