module Mapper
  require_relative 'PriceReader'
  # responsible for loading price-lists and comparing them
  class PriceManager
    attr_reader :prices
    def initialize(*options)
      @prices = Array.new # <= array of Price objects
      @mutex = Mutex.new # <= for synchronization between threads
      @timeMeasure = Hash.new # <= for measuring block execution
      @price_extensions = ["xlsx"]#, "xlsx"]
      default_options = {:dir=>"prices"}
      #p *options
      #define_prices_extensions
      (options.empty?) ? @options = default_options : @options = options[0] # <= default value
      load_from_dir
      #(options.empty?) ?  load_from_dir : loadPrices(@options[:filenames])
    end
    #зчитує файли з потрібною директорії
    def load_from_dir *dir
      (dir.empty?) ? dir = @options[:dir] : dir = dir[0]
      Dir.chdir(dir);
      extensions = @price_extensions.join(",")
      #p Dir["*"]
      filenames = Dir.glob("*.{#{extensions}}")
      #p filenames
      load_prices filenames
    end
    # приймає масив прайсів
    def load_prices(filenames)
      p "is array: #{filenames.kind_of?(Array)}"
      p "is empty: #{filenames.empty?}"
      #перевіряємо чи це масив
      p filenames
      raise ArgumentError, 'must be array of files #{filenames.kind_of?}' unless filenames.kind_of?(Array) 
      #витягуємо зміст прайс-листа для подальшої обробки
      time_load_prices = Time.now
      @timeMeasure[:loadPrices] = {};
      puts Dir.pwd
      threads = filenames.each do |filename|
        p "Filename now is procesed: #{filename}"
        reader = PriceReader.new filename
        reader.parse
        next
        #! Виміряв час з потоками та без, різниця невелика 
        #t = Thread.new do # <= UNCOMMENT
        data = get_data_from_price(filename)
        # @mutex.synchronize do # <= UNCOMMENT
        p "Filename: #{filename} type: #{filename.class}"
        p "Data type: #{data.class}"
        @prices << Price.new(filename, data) if filename.kind_of?(String) and data.nil? == false
        # end # <= UNCOMMENT
        #end # <= UNCOMMENT
        #t.join # <= UNCOMMENT
      end
      @timeMeasure[:loadPrices][:duration] = Time.now - time_load_prices
      #p @timeMeasure
    end
    # визначає які типи розширень прайсів, клас може опрацювати
    # {ФОРМАТ}_Reader <= файли, які опрацьовують відповідні формати
    # приклад: CSV_Reader.rb <= Клас, який опрацьовує формат csv
    def define_prices_extensions
      @price_readers = Array.new # <= масив форматів, які підтримує клас
      @price_extensions = Array.new
      readers = Dir["*_Reader.rb"]
      #p readers
      raise StandartError "No price readers" if readers.nil? || readers.empty?
      readers.each do |filename| # <= array with filenames of classes
        match = filename.match /((^[A-Z]+)_Reader).rb$/
        #p "Match #{match}"
        format = match[2].downcase
        @price_readers << {:file=> match[0], :klass=> match[1], :extension=> format}
        @price_extensions << format
      end
      #p @price_extensions
      @price_readers
    end
    # повертає хеш-таблицю з результатами
    def get_data_from_price(filename)
      @price_readers.each do |reader|
        #p "format: #{reader[:extension]}, filename: #{filename}"
        match =  filename.match /.#{reader[:extension]}$/
        
        if(match.kind_of?(MatchData))
          # <= завантажуємо необхідний клас та створюємо обєкт
          begin
            require_relative reader[:file] unless Module.const_defined? reader[:klass] # <= Завантажуємо файл, якщо відповідний клас не визначений
            class_name = Module.const_get(reader[:klass])
            #p "Class: #{class_name} is loaded"
            obj = class_name.new filename
            return obj.data
            #p "Class #{reader[:klass]} successfully loaded!"
          rescue LoadError => e
            puts "Such class #{reader[:klass]} doesn't exist!"
          rescue NameError => e
            p e
          end
        end
      end
    end
  end
  class Price
    def initialize(filename, data)
      @title, @data = filename, data[:table]
      p "Successfully processed #{filename} with #{@data.length} entities!"
      p @data
    end
  end
end

Mapper::PriceManager.new({:dir=>"prices/test"})
