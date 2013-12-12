module Mapper
    
  # responsible for loading price-lists and comparing them
  class PriceManager
    attr_reader :prices
    def initialize(*filenames)
      @prices = Array.new # <= array of Price objects
      @mutex = Mutex.new # <= for synchronization between threads
      @timeMeasure = Hash.new # <= for measuring block execution
      (filenames.empty?) ?  loadFromDir("prices") : loadPrices(filenames)
    end
    def loadFromDir dir
	Dir.chdir(dir);
      	filenames = Dir.glob("*.{csv,xls,xlsx}")
	loadPrices filenames, dir
    end
    # приймає масив прайсів
    def loadPrices(filenames, *dir)
      #p "is array: #{filenames.kind_of?(Array)}"
      #p "is empty: #{filenames.empty?}"
      #перевіряємо чи це масив
      raise ArgumentError, 'must be array of files #{filenames.kind_of?}' unless filenames.kind_of?(Array) 
      #витягуємо зміст прайс-листа для подальшої обробки
      time_load_prices = Time.now
      @timeMeasure[:loadPrices] = {};
      puts Dir.pwd
      threads = filenames.each do |filename|
	#! Виміряв час з потоками та без, різниця невелика 
        #t = Thread.new do # <= UNCOMMENT
          content = File.read filename
         # @mutex.synchronize do # <= UNCOMMENT
		@prices << Price.new(filename, content)
         # end # <= UNCOMMENT
        #end # <= UNCOMMENT
        #t.join # <= UNCOMMENT
      end
      @timeMeasure[:loadPrices][:duration] = Time.now - time_load_prices
      p @timeMeasure
    end
  end
  class Price
    def initialize(filename, content)
      @title, @content = filename, content
      p "Successfully created Price object!"
    end
  end
end

Mapper::PriceManager.new 
