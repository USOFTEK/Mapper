require 'active_record'
class CreatePrices < ActiveRecord::Migration
  def self.connect config
    ActiveRecord::Base.establish_connection config
  end
	def self.up
    self.down
		create_table :prices, :options => "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
			t.column :price, :string, :null => false
			t.timestamps
		end
	end
	def self.down
		drop_table :prices
	end
end
