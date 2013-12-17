#обробляє файли в залежності від формату
class PriceReader
  attr_reader :data
	def initialize(filename)
    @price = filename
		@data =  parseByHeaders "Код", "Артикул", "Повна назва"
	end
  def parseByHeaders(headers)
     p "File: #{@price} is proceding with headers: #{headers.join(",")}"
  end
  def to_s
    p "Count of items: #{@data.length}"
  end
end
