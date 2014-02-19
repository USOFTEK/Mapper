require 'active_record'

class CreateComparisons < ActiveRecord::Migration
  def self.connect config
    ActiveRecord::Base.establish_connection config
  end
  def self.up
    self.down
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
    begin
      drop_table :comparisons
    rescue ActiveRecord::StatementInvalid => e
      p e.message
    rescue Mysql2::Error => e
      p e.message
    end
  end
end


