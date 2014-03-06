# responsible for loading price-lists and comparing them
class PriceManager < Mapper::Base
  attr_reader :dictionary
  attr_accessor :search_worker
  
  def initialize
    super
  end
  def get_price_names *dir
    (dir.empty?) ? @prices_dir = @options[:dir] : @prices_dir = dir[0]
    
    FileUtils.cd @prices_dir 
    extensions = @config["extensions"].join(",")
    @filenames = Dir.glob("*.{#{extensions}}")
    raise "Error", "No prices :(" if @filenames.count == 0
    @filenames
  end
  def print message
    @logger.debug message
    @output.print message
  end
  def get_hash(filename)
    Digest::SHA256.file(filename).hexdigest
  end
  #TODO: перевіряти розмір або хеш файлу, якщо змінився проводити парсинг ще раз
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
  def load_prices(*params)
    get_price_names
    (params.empty?) ? filenames = @filenames : filenames = params[0]
    raise ArgumentError, 'must be array of files #{filenames.kind_of?}' unless filenames.kind_of?(Array) 
    @price_count = filenames.size
    @counter = 0
    EM::Synchrony::FiberIterator.new(filenames, @config["concurrency"]["iterator_size"]).map do |filename|
      check_price filename
    end
  end
end
