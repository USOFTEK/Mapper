require 'smarter_csv'
class CSV_Parser
	#include CSV
	def initialize (filename)
		@csv = filename
	end
	def parseByHeaders(*fields)
		raise ArgumentError unless fields.kind_of?(Array)
		p fields
		prices = SmarterCSV.process(@csv,
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
		p prices
	end
end

#csv = CSV_Parser.new "data/price_piece_csv.csv"
#csv = CSV_Parser.new "data/example.csv"
csv = CSV_Parser.new "prices/ktc.csv"
csv.parseByHeaders "Код", "Артикул", "Повна назва"
