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
    begin
      drop_table :prices
    rescue ActiveRecord::StatementInvalid => e
      p e.message
    rescue Mysql2::Error => e
      p e.message
    end
  end
end
