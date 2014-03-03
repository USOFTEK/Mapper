class StorageComparison < NonBlockingDB
  def initialize db
    @db_name = 'comparisons'
    super db
  end
  def link(storage_item_id, shop_item_id, linked)
    query = "INSERT INTO `#{@db_name}` (storage_item_id, shop_item_id, linked) VALUES ('#{storage_item_id}', '#{shop_item_id}', #{linked})"
    @db.aquery query, :as => :array
	end
  def empty
    @db.query "DELETE FROM `#{@db_name}`", :async => false
  end
end
