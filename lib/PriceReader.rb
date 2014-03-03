require 'simple-spreadsheet'
#визначає заголовки у прайсі та витянує дані
class PriceReader
  attr_reader :data, :dictionary
	def initialize(filename, dictionary)
    @price = filename
    @threads = []
    @data = {:headers => {}, :line => nil, :results => []}
    @s = SimpleSpreadsheet::Workbook.read(@price)
    @size = {:first_row => @s.first_row, :last_row => @s.last_row, :first_column => @s.first_column, :last_column => @s.last_column}
    @dictionary = dictionary
	end
  #приймає комірку і проводить пошук на сумісність
  #TODO: добавити пріоритет назв полів якщо є code i model тоді model
  def find_in_dictionary(cell, line, column)
    @dictionary.each do |key,value| # <= code: ["Код", "code"]
            next if @data[:headers] and @data[:headers][key]
            value.each do |word|
              result = /^.*#{word}/i.match(cell) # <= правильно вибрати слово 
              if(result)
                #p "Cell #{cell} matched with #{key}: on line #{line} and column: #{column}"
                @data[:headers][key] = {:line => line, :column => column, :cell => cell}
                @data[:line] = line if @data[:line].nil?
              end
            end
      end
  end
  # перевірює повноту співпадіння
  def check_headers_match
    #raise "Headers are not defined!" if @data[:headers].nil?
    #raise "Title is not defined!" if @data[:headers][:title].nil?
    #raise "Only one header found" if @data[:headers].length < 2
    @data[:headers] && @dictionary.length == @data[:headers].length
  end
  def get_headers_match_results
    if check_headers_match
      p "Found all #{@data[:headers].length} headers!"
    else
      p "Found headers count: #{@data[:headers].length} from #{@dictionary.length}"
    end
  end
  # шукає заголовки в строці
  def find_header_in_line(line)
     #p "Line: #{line}"
     @size[:first_column].upto(@size[:last_column]) do |column|
        cell,  celltype = @s.cell(line, column), @s.celltype(line,column)
        find_in_dictionary(cell, line, column) if celltype == :string and cell.length < 20
        break if check_headers_match
     end
  end
  #for default headers are in the head of the price 
  def define_headers
    #from head to bottom
    @size[:first_row].upto(@size[:last_row]) do |line|
      find_header_in_line(line)
      break if @data[:line] # <= якщо знайдений хоча б один заголовок, припиняємо пошуки строки
    end 
    @data
  end
  #Витягує інформацію відносно заголовків
  def parse
    define_headers
   start_line = @data[:line] + 1 # піля заголовків йдуть потрібні дані
        start_line.upto(@size[:last_row]) do |line|
          hash, flag = Hash.new, true
          @data[:headers].each do |header, value|
            cell = @s.cell(line, value[:column]) 
            unless cell.nil? 
              hash[header] = cell.to_s.strip
            else
              flag = false
              break
            end
          end
          @data[:results] << hash if flag
    end
    #p @data[:results][0..10]
    @data[:size] = @size
    @data
  end
end 