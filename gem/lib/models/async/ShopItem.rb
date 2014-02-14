class ShopItem < NonBlockingDB
  def initialize db
    @query_all = "SELECT up.product_id, name, code, model FROM `uts_product` as up INNER JOIN `uts_product_description` as upd ON up.product_id = upd.product_id"
    super db
  end
  def all
    @db.aquery @query_all, :as => :array
  end
  def find_by_id id
    query =  "#{@query_all}  WHERE up.product_id = '#{id}'"
    @db.aquery query, :as => :hash
  end  
end
