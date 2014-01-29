module Mapper
  require_relative 'PriceReader'
  require_relative 'models/Prices'
  require_relative 'models/Products'
  require 'benchmark'
  require 'em-synchrony'
  require 'em-synchrony/mysql2'
  require 'amqp'

  # responsible for loading price-lists and comparing them
  class PriceManager
    attr_reader :prices
    def initialize(*options)
      @prices = Array.new # <= array of Price objects
      @price_extensions = ["xlsx"] # <= csv, xlsx
      default_options = {:dir=>"prices", :test => false}
      #TODO: налаштування бази винести в окремий файл db_confif.yaml
      @db_options = {:host => 'localhost', :username => 'root', :password => '238457', :database => 'test'}
      @concurrency = 4
      @pool_size = 4
      (options.empty?) ? @options = default_options : @options = options[0] # <= default value
      set_db_client
    end
    def start
      EM.synchrony do
          AMQP.start do |connection|
            puts "AMQP started"
            channel = AMQP::Channel.new connection
            queue = channel.queue("rabbit.mapper", :auto_delete => true)
            exchange = channel.direct("")
            queue.subscribe do |payload|
              puts "Received message #{payload}"
              connection.close {EM.stop} if payload == "stop"
            end
          end
          load_from_dir
      end
    end
    #зчитує файли з потрібною директорії
    def load_from_dir *dir
      (dir.empty?) ? dir = @options[:dir] : dir = dir[0]
      Dir.chdir(dir);
      extensions = @price_extensions.join(",")
      filenames = Dir.glob("*.{#{extensions}}")
      load_prices(filenames) # <= should be parallelized!
    end
    # приймає масив прайсів
    def load_prices(filenames)
      raise ArgumentError, 'must be array of files #{filenames.kind_of?}' unless filenames.kind_of?(Array) 
      @price_count = filenames.size
      @counter = 0
      EM::Synchrony::Iterator.new(filenames, @concurrency).map do |filename, iter|
        #TODO: перевіряти розмір або хеш файлу, якщо змінився проводити парсинг ще раз
        unless Price.find_by_price(filename) # <= # перевірка імені прайсу
          p "Filename now is procesed: #{filename}"
          operation = proc {PriceReader.new(filename).parse }
          callback = proc do |data|
            EM.defer(proc { insert_data(data, filename)})
            iter.return
          end
          EM.defer(operation, callback)
        else
          p "Price #{filename} already exists in database!"
        end
      end
      p "Finished"
      #EM.stop
    end
    def set_db_client
      @db = EventMachine::Synchrony::ConnectionPool.new(:size => @pool_size) do
        Mysql2::EM::Client.new(@db_options)
      end
    end
    # занесення прайсів у базу
    def escape_row(row)
      @db.escape row || "NULL"
    end
    def insert_data(data, filename)
      insertion = @db.aquery "INSERT INTO `prices` (`price`) VALUES ('#{filename}')"
      insertion.callback do 
          price_id = @db.last_id
          client = @db
          values = []
          query_string =  "INSERT INTO `products` (`code`, `title`, `article`, `price_id`) VALUES "
          data[:results].each do |row|
            values << "('#{escape_row row[:code]}','#{escape_row row[:title]}','#{escape_row row[:article]}','#{price_id}')"
          end
          query = query_string + values.join(",")
          @db.aquery(query).callback {
            p "#{filename} successfully inserted!"
          }
      end
    end
  end
end
#Todo: inherit parent constructor and its params
class Test < Mapper::PriceManager
  def benchmark
    Benchmark.bm do |x|
      x.report("insert")do
        load_from_dir 
      end
    end
  end
end
Mapper::PriceManager.new({:dir=>"prices/test", :test => false}).start
