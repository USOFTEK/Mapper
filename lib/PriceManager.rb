# responsible for loading price-lists and comparing them
class PriceManager < Mapper::Base
  attr_reader :dictionary
  def initialize
    super
    p "Directory #{@config['dir']}"
  end
  #зчитуємо прайси з поточної директорії, якщо директорія не вказана
  # в налаштуваннях, інакше зчитуємо прайси з поточної директорії
  def get_price_names
    FileUtils.cd @config['dir'] if @config['dir'].nil? == false && Dir.exists?(@config['dir'])
    extensions = @config["extensions"].join(",")
    filenames = Dir.glob("*.{#{extensions}}")
    raise StandardError, "No prices in #{@config['dir']} directory :( " if filenames.count == 0
    filenames
  end
  def get_hash(filename)
    Digest::SHA256.file(filename).hexdigest
  end
  def check_price filename
    # отримуємо хеш файлу, щоб в подальшому порівняти з тим що міститься у базі
    hash = get_hash(filename)
    unless @price.check(filename, hash)
      parse(filename, hash)
    else
      @price_count -= 1
      print "Price #{filename} already exists in database!"
    end
  end
  def parse(filename, hash)
    EM.defer(
      proc {PriceReader.new(filename, @dictionary["headers"]).parse },
      proc do |data|
        EM.defer(
          proc do
            @price.add(filename, hash).callback do
              result = Fiber.new {@storage_item.add(data, filename)}.resume
              result.callback do
                @counter += 1;
                print "#{filename} #{@counter} / #{@price_count}successfully added"
                print "Operation index has been successfully finished" if @counter == @price_count
              end
              result.errback{|error| p error}
            end
          end
        )
      end
    )
  end
  # приймає масив прайсів
  def load_prices
    filenames = get_price_names
    raise ArgumentError, "must be array of files #{filenames.kind_of?}" unless filenames.kind_of?(Array) 
    @price_count = filenames.size
    @counter = 0
    EM::Synchrony::FiberIterator.new(filenames, @config["concurrency"]["iterator_size"]).map do |filename|
      check_price filename
    end
  end
end
