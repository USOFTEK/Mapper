require_relative '../db/database'

class ProductComparison < ActiveRecord::Base
	def self.link(price_product_id, shop_product_id)
		result = self.create({:price_product_id => price_product_id, :shop_product_id => shop_product_id})
	end
end

#price = Product.create({code: "1232", title: "Laptop", article: "KHSDKFH23423kjh23j"})
#p Product.all
