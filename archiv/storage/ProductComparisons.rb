require_relative "connection.rb"

class ProductComparison < ActiveRecord::Base
	establish_connection config
	def self.link(price_product_id, shop_product_id)
		result = self.create({:price_product_id => price_product_id, :shop_product_id => shop_product_id})
	end
end

