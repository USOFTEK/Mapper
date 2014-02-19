require 'active_record'

class CreateProducts < ActiveRecord::Migration
  def self.connect config
    ActiveRecord::Base.establish_connection config
  end
  def self.up
    self.down
    create_table :products, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.column :code, :string
      t.column :title, :string, :null => false
      t.column :article, :string
      t.column :price_id, :integer
      
      t.timestamps 
    end
    add_index :products, :price_id
  end
  def self.down
    begin
      drop_table :products
    rescue ActiveRecord::StatementInvalid => e
      p e.message
    rescue Mysql2::Error => e
      p e.message
    end
  end
end


