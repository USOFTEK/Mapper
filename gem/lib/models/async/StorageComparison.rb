class StorageComparison < NonBlockingDB
  def initialize db
    @db_name = 'comparisons'
    super db
  end
  def link(storage_item_id, shop_item_id)
    query = "INSERT INTO `#{@db_name}` (storage_item_id, shop_item_id) VALUES ('#{storage_item_id}', '#{shop_item_id}')"
    @db.aquery query, :as => :array
	end
end
