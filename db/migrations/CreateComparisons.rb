require 'active_record'

class CreateComparisons < ActiveRecord::Migration
  def self.up
    create_table :comparisons, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.column :storage_item_id, :integer, :null => false
      t.column :shop_item_id, :integer, :null => false
      t.column :precision, :integer
      t.column :linked, :boolean, :default => false
      t.timestamps 
     end
	add_index :comparisons, :storage_item_id
  add_index :comparisons, :shop_item_id
    end
    def self.down
      drop_table :comparisons
    end
end


