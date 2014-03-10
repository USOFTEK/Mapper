require "em-synchrony"
require "active_record"
require "em-synchrony/activerecord"

class ActiveRecord::Base
  def self.environment
    raise Error, "Mapper env is not defined!" if ENV['MAPPER_ENV'].nil?
    ENV['MAPPER_ENV']
  end
  def self.check_filename filename
    (File.exists?(filename)) ? filename : File.join(File.dirname(__FILE__),filename)
  end
  def self.check_dirname dirname
    (Dir.exists?(dirname)) ? dirname : File.join(File.dirname(__FILE__),dirname)
  end
  def self.connect db
    self.table_name_prefix = "#{db}."
    config = "../../config/config.yaml"
    @config = YAML.load_file(check_filename config)[environment]["db"][db]
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
    FileUtils.cd(check_dirname "../../db/migrate")
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
  
  self.table_name = "shop.uts_product"
  self.primary_key = "product_id"
  belongs_to :uts_product_description, :foreign_key => "product_id"
  has_one :comparison, :foreign_key => "shop_item_id", :dependent => :destroy
end

class UtsProductDescription < ShopBase
 
  self.table_name = "shop.uts_product_description"
  self.primary_key = "product_id"
  has_one :uts_product
end

