require_relative "connection.rb"

class Product < ActiveRecord::Base
	establish_connection config
	belongs_to :price
end

