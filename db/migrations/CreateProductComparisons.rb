require 'active_record'

class CreateProductComparisons < ActiveRecord::Migration
  def self.up
    create_table :product_comparisons, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.column :price_product_id, :integer, :null => false
      t.column :shop_product_id, :integer, :null => false
      t.column :precision, :integer
      t.column :linked, :boolean, :default => false
      t.timestamps 
     end
	add_index :product_comparisons, :price_product_id
  add_index :product_comparisons, :shop_product_id
    end
    def self.down
      drop_table :product_comparisons
    end
end


