require_relative '../db/database'

class Product < ActiveRecord::Base
	belongs_to :price
end

#price = Product.create({code: "1232", title: "Laptop", article: "KHSDKFH23423kjh23j"})
#p Product.all
