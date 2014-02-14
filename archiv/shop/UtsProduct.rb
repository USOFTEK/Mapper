require_relative "connection.rb"

class UtsProduct < ActiveRecord::Base
	establish_connection config
	self.table_name = "uts_product"
	self.primary_key = "product_id"
	belongs_to :uts_product_description, foreign_key: "product_id"
end
