module Mapper
  require_relative 'PriceReader'
  require_relative 'models/Prices'
  require_relative 'models/Products'
  require 'benchmark'
  require 'em-synchrony'
  require 'em-synchrony/mysql2'

  # responsible for loading price-lists and comparing them
  class PriceManager
    attr_reader :prices
    def initialize(*options)
      @prices = Array.new # <= array of Price objects
      @price_extensions = ["xlsx"] # <= csv, xlsx
      default_options = {:dir=>"prices", :test => false}
      @db_options = {:host => 'localhost', :username => 'root', :password => '238457', :database => 'test'}
      @concurrency = 4
      @pool_size = 4
      (options.empty?) ? @options = default_options : @options = options[0] # <= default value
      set_db_client
    end
    def start
      EM.synchrony{load_from_dir}
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
    def insert_data(data, filename)
      insertion = @db.aquery "INSERT INTO `prices` (`price`) VALUES ('#{filename}')"
      insertion.callback do 
          price_id = @db.last_id
          client = @db
          values = []
          query_string =  "INSERT INTO `products` (`code`, `title`, `article`, `price_id`) VALUES "
          data[:results].each do |row|
            code = client.escape row[:code] || "NULL"
            title = client.escape row[:title] || "NULL"
            article = client.escape row[:article] || "NULL"
            values << "('#{code}','#{title}','#{article}','#{price_id}')"
          end
          query = query_string + values.join(",")
          @db.aquery(query).callback {
            p "#{filename} successfully inserted!"
            @counter += 1
            EM.stop if @counter == @price_count
          }
      end
    end
  end
end
#Todo: inherit parent constructor and its params
class Test < Mapper::PriceManager
  def empty_products
    Price.delete_all
    Product.delete_all
  end
  def benchmark
    Benchmark.bm do |x|
      x.report("delete"){empty_products}
      x.report("insert")do
        load_from_dir 
      end
    end
  end
end
Mapper::PriceManager.new({:dir=>"prices/test", :test => false}).start
