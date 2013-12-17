require 'smarter_csv'
class CSV_Reader < PriceReader
	attr_reader :data
	def parseByHeaders(*fields)
    super(fields)
		raise ArgumentError unless fields.kind_of?(Array)
		prices = SmarterCSV.process(@price,
			user_provided_headers: fields,
			remove_empty_hashes:true,
			headers_in_file:false,
		 	strip_whitespace:true
		)
		#видаляємо ті записи, які не містять достатньо даних
		#! причина неправильні розміщені заголовки у файлі
		prices.reject! do |row|
      			row if row.size < 2 
		end
		prices
	end
end


