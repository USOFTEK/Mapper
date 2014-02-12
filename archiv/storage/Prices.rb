require_relative "connection.rb"

class Price < ActiveRecord::Base
	establish_connection config
	has_many :products
end

