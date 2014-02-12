require_relative "connection.rb"

class UtsProductDescription < ActiveRecord::Base
	establish_connection config
	self.table_name = "uts_product_description"
	self.primary_key = "product_id"
	has_one :uts_product
end
