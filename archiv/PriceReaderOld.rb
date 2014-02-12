#обробляє файли в залежності від формату
class PriceReader
	def initialize(filename)
		# якщо формат файлу csv тоді створюємо обєкт класу CsvReader
		# якщо .xlsx => XlsxReader
		setupFormats
		@priceReaders.each do |reader|
			match =  filename.match /.#{reader[:format]}$/
			#p "Current format #{reader[:format]} = #{match}"
			if(match.kind_of?(MatchData))
				# <= завантажуємо необхідний клас та створюємо обєкт
				begin
					require_relative reader[:file]
					class_name = Module.const_get(reader[:klass])
					obj = class_name.new filename
					p obj.data
					#p "Class #{reader[:klass]} successfully loaded!"
					# створюємо обєкт цього класу і виконуємо операцію
					# записуємо результат
					# виходимо з циклу
				rescue LoadError => e
					puts "Such class #{reader[:klass]} doesn't exist!"
				rescue NameError => e
					p e
				rescue TypeError => e
					p e
				end
			end
		end
	end
	#визначаємо формати прайс-листів, які може опрацювати клас
	def setupFormats
		@priceReaders = Array.new # <= масив форматів, які підтримує клас
		readers = Dir["*_Reader.rb"]
		#p readers
		raise StandartError "No price readers" if readers.nil? || readers.empty?
		readers.each do |filename| # <= array with filenames of classes
			match = filename.match /((^[A-Z]+)_Reader).rb$/
			#p "Match #{match}"
			@priceReaders << {file: match[0], klass: match[1], format: match[2].downcase}
		end
		#p @priceReaders
	end
end

#PriceReader.new "prices/ktc.csv"
PriceReader.new "prices/ktc1.xlsx"
