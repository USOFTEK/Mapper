require 'rubyXL'

workbook = RubyXL::Parser.parse("prices/ktc1.xlsx")
data = workbook[0].get_table(["code"])
puts data


#oo.to_csv('ktc.csv') # <= конвертування
