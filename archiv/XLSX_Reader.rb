require 'rubyXL'
class XLSX_Reader < PriceReader
	attr_reader :data
	def parseByHeaders(*headers)
    super(headers)
		workbook = RubyXL::Parser.parse @price
    data = workbook[0].get_table(headers) # <= перевірити на nil
    if data.nil?
      raise "No data found in price. Check correctly headers" 
    else
      return data
    end
	end
end

