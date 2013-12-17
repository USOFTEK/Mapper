require 'rubyXL'
class XLSX_Reader < PriceReader
	attr_reader :data
	def initialize(filename)
		@price = filename
		@data = parseByHeaders "code"
	end
	def parseByHeaders(*headers)
    super(headers)
		workbook = RubyXL::Parser.parse @price
    workbook[0].get_table(headers) # <= має бути словник заголовків
	end
end

