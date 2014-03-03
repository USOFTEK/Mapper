require_relative 'utm_mapper'

mapper = Mapper::Base.new
p result = mapper.storage_comparison.is_empty?
#p result.each {|row| p row}
