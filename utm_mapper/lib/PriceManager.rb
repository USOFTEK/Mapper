
# responsible for loading price-lists and comparing them
class PriceManager
  attr_reader :prices
  
  def initialize(*options)
    @prices = Array.new # <= array of Price objects
    default_options = {:dir=>"prices", :env => 'production'}
    (options.empty?) ? @options = default_options : @options = options[0] # <= default value
    @config = YAML.load_file('config.yaml')[@options[:env]]
    @dictionary = YAML.load_file('dictionary.yaml')
    register_async_models
    set_logger
    get_prices_from_dir
    @search_worker = SearchWorker.new @config["search"], @dictionary["search"] # <= пошук
    Thread.abort_on_exception=true
  end
  def start_webserver
      WebServer.run!
  end
  def register_async_models
    @price = StoragePrice.new "storage"
    @shop_item = ShopItem.new "shop"
    @storage_item = StorageItem.new "storage"
    @storage_comparison = StorageComparison.new "storage"
  end
  def start
    p "Mapper has been started"
    #start_webserver
    EM.synchrony do
      
      AMQP.start do |connection|
        @logger.debug "AMQP started"
        channel = AMQP::Channel.new connection
        queue = channel.queue(@config["broker"]["queue_name"], :auto_delete => true)
        #exchange = channel.direct("default")
        #queue.bind(exchange)
        queue.subscribe do |payload|
          @logger.debug "Received message #{payload}"
          connection.close {EM.stop} if payload == "stop"
          Fiber.new {load_prices}.resume if payload == "start"
          Fiber.new {match}.resume if payload == 'match'
          Fiber.new {start_webserver}.resume if payload == 'web'
          EM.defer {@search_worker.index} if payload == 'index'
        end
      end
      #Fiber.new {load_prices}.resume
      #Fiber.new {match}.resume
    end
  end
  def set_logger
    @logger = Logging.logger['example']
    @logger.add_appenders(
      Logging.appenders.stdout,
      Logging.appenders.file('log/development.log')
    )
    @logger.level = :debug
  end
  #зчитує файли з потрібною директорії
  def get_prices_from_dir *dir
    (dir.empty?) ? dir = @options[:dir] : dir = dir[0]
    @current_dir = Dir.pwd
    Dir.chdir(dir);
    extensions = @config["extensions"].join(",")
    @filenames = Dir.glob("*.{#{extensions}}")
    #Dir.chdir current_dir
  end
  # приймає масив прайсів
  def load_prices(*params)
    (params.empty?) ? filenames = @filenames : filenames = params[0]
    raise ArgumentError, 'must be array of files #{filenames.kind_of?}' unless filenames.kind_of?(Array) 
    @price_count = filenames.size
    @counter = 0
    EM::Synchrony::FiberIterator.new(filenames, @config["concurrency"]["iterator_size"]).map do |filename, iter|
      #TODO: перевіряти розмір або хеш файлу, якщо змінився проводити парсинг ще раз
      unless @price.check(filename) # <= # перевірка імені прайсу
        p "Filename now is procesed: #{filename}"
        operation = proc {PriceReader.new(filename, @dictionary["headers"]).parse }
        callback = proc do |data|
          EM.defer(
            proc do
              @price.add(filename).callback do
                result = @storage_item.add(data, filename)
                result.callback do
                  @counter += 1;
                  p "#{filename} #{@counter} / #{@price_count}successfully added"
                  insertion_finished if @counter == @price_count
                end
                result.errback{|error| p error}
              end
            end
          )
        end
        EM.defer(operation, callback)
      else
        p "Price #{filename} already exists in database!"
      end
    end
    p "Finished"
  end
  def insertion_finished
    p "Insertion has been finished successfully!"
    p "Do you want to start matching products? Type 'Y' or 'N'"
    command = gets.chomp.downcase
    Fiber.new{match}.resume if command == 'y'
    EM.stop if command == 'n'
  end
  # співставлення
  def match
       
    EM::Synchrony::FiberIterator.new(@storage_item.all, @config["concurrency"]["iterator_size"]).each do |product, iter|
      begin
        @logger.debug response = @search_worker.find({
            :title => product["title"],
            :model => product["code"]}
        )
        if response[:count] > 0
          shop_product_id = response.docs[0]["id"].to_i
          price_product_id = product["id"]
          #TODO: precision = response[:precision] визначення точності результату пошуку
          @storage_comparison.link(price_product_id, shop_product_id).errback {|error|p error}
        end
      rescue => e
        p e
      end
    end
  end
end
