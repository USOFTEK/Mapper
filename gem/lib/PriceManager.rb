
# responsible for loading price-lists and comparing them
class PriceManager < Mapper::Base
  
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
  # приймає масив прайсів
  def load_prices(*params)
    
    get_price_names
    (params.empty?) ? filenames = @filenames : filenames = params[0]
    raise ArgumentError, 'must be array of files #{filenames.kind_of?}' unless filenames.kind_of?(Array) 
    @price_count = filenames.size
    @counter = 0
    EM::Synchrony::FiberIterator.new(filenames, @config["concurrency"]["iterator_size"]).map do |filename, iter|
      p filename
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
                  @logger.debug "Operation index has been successfully finished" if @counter == @price_count
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
  end
end