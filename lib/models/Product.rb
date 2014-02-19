require "em-synchrony"
require "active_record"
require "em-synchrony/activerecord"

class ActiveRecord::Base
  def self.environment
    "development"
  end
  def self.connect db
    #(db.nil?) ? db = self.name.match(/^[A-Z][a-z]+/)[0].downcase : db = db[0]
    self.table_name_prefix = "#{db}."
    config = "config.yaml"
    config = File.join(File.dirname(__FILE__), config) unless File.exists? config
    @config = YAML.load_file(config)[environment]["db"][db]
    @config["adapter"] = @config["active_adapter"]
    establish_connection @config
  end
end

class StorageBase < ActiveRecord::Base
  
  self.abstract_class = true
  connect "storage"
  def self.table_name_prefix
    "storage."
  end
  def self.setup
    FileUtils.cd "migrations"
    Dir.glob("*.rb").each do |file|
      require_relative "#{Dir.pwd}/#{file}"
      klass_name = file.split(".")[0]
      klass = Object.const_get(klass_name)
      klass.connect self.connection_config
      klass.up
    end
  end
end

class ShopBase < ActiveRecord::Base
  
  self.abstract_class = true
  connect "shop"
end

class Product < StorageBase
  
  belongs_to :price
  has_one :comparison, :foreign_key => "storage_item_id", :dependent => :destroy
  
  def self.get_all
    select = "DISTINCT storage.comparisons.id as id,storage.products.id as storage_id,storage.products.title as storage_title,storage.products.code as storage_code,storage.products.article as storage_article,storage.comparisons.linked as linked,shop.uts_product.product_id as shop_id,shop.uts_product_description.name as shop_title,shop.uts_product.code as shop_code, shop.uts_product.model as shop_model"
    sql = Product.joins(:comparison => {:uts_product => :uts_product_description}).select(select).to_sql
    self.connection.execute(sql)
  end
end

class Price < StorageBase
  
  has_many :products
end

class Comparison < StorageBase
  
  belongs_to :product, :foreign_key => "storage_item_id", :dependent => :destroy
  belongs_to :uts_product, :foreign_key => "shop_item_id", :dependent => :destroy
  
end

class UtsProduct < ShopBase
  
  
  #default_scope {select("shop.uts_product.code as code,shop.uts_product.model as model, shop.uts_product_description.name as title").joins(:uts_product_description)}
  self.table_name = "shop.uts_product"
  #self.table_name_prefix = "shop."
    
  self.primary_key = "product_id"
  belongs_to :uts_product_description, :foreign_key => "product_id"
  has_one :comparison, :foreign_key => "shop_item_id", :dependent => :destroy
  
end

class UtsProductDescription < ShopBase
 
  self.table_name = "shop.uts_product_description"
  self.primary_key = "product_id"
  has_one :uts_product
end

#p Price.find_by_price("ktc.xlsxx")
#p "============================"
#p Product.first
#p "============================"
#p Product.joins(:comparison).to_sql
#select = "DISTINCT storage.products.id as storage_id,storage.products.title as storage_title,storage.products.code as storage_code,storage.products.article as storage_article,shop.uts_product.product_id as shop_id,shop.uts_product_description.name as shop_title,shop.uts_product.code as shop_code, shop.uts_product.model as shop_model"
#p Product.joins(:comparison => {:uts_product => :uts_product_description}).select(select).to_sql
#p "============================"
#UtsProduct.get_all
#p Product.joins(:comparison).limit(1).load
#p "============================"
#p UtsProductDescription.first

#p UtsProduct.joins(:uts_product_description, :comparison).to_sql
#p UtsProduct.first(:includes => :uts_product_description).limit(1)


#p UtsProduct.first.uts_product_description
#p UtsProduct.joins(:uts_product_description).select("uts_product_description.name, shop.uts_product.code").to_sql
#p UtsProduct.


