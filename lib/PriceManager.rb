# responsible for loading price-lists and comparing them
class PriceManager < Mapper::Base
  attr_reader :dictionary
  attr_accessor :search_worker
  
  def initialize
    super
  end
  #зчитує файли з потрібною директорії
  def get_price_names *dir
    (dir.empty?) ? @prices_dir = @options[:dir] : @prices_dir = dir[0]
    
    FileUtils.cd @prices_dir 
    extensions = @config["extensions"].join(",")
    @filenames = Dir.glob("*.{#{extensions}}")
  end
  def print message
    @logger.debug message
    @output.print message
  end
  def check_price filename
    unless @price.check filename
      parse filename
    else
      @price_count -= 1
      @output.print "Price #{filename} already exists in database!"
    end
  end
  def parse filename
    EM.defer(
      proc {PriceReader.new(filename, @dictionary["headers"]).parse },
      proc do |data|
          EM.defer(
            proc do
              @price.add(filename).callback do
                result = Fiber.new {@storage_item.add(data, filename)}.resume
                result.callback do
                  @counter += 1;
                  p "#{filename} #{@counter} / #{@price_count}successfully added"
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
      #TODO: перевіряти розмір або хеш файлу, якщо змінився проводити парсинг ще раз
      #unless @price.check(filename) # <= # перевірка імені прайсу
      #  p "Filename now is procesed: #{filename}"
      #  operation = proc {PriceReader.new(filename, @dictionary["headers"]).parse }
      #  callback = proc do |data|
      #    EM.defer(
      #      proc do
      #        @price.add(filename).callback do
      #          result = Fiber.new {@storage_item.add(data, filename)}.resume
      #          result.callback do
      #            @counter += 1;
      #            p "#{filename} #{@counter} / #{@price_count}successfully added"
      #            print "Operation index has been successfully finished" if @counter == @price_count
      #          end
      #          result.errback{|error| p error}
      #        end
      #      end
      #    )
      #  end
      #  EM.defer(operation, callback)
      #else
      #  @price_count -= 1
      #  @output.print "Price #{filename} already exists in database!"
      #end
    end
  end
end
