class StorageItem < DB
  attr_reader :db
  def initialize db
    super db
  end
  def escape_row(row)
    @db.escape row || "NULL"
  end
  def all
    p "fetching all products..."
    @db.query("SELECT id,title,code FROM `products`", :as => :hash, :async => false)
  end 
  def add(data, filename)
   
      price_id = @db.last_id
      values = []
      query_string =  "INSERT INTO `products` (`code`, `title`, `article`, `price_id`) VALUES "
      data[:results].each do |row|
        values << "('#{self.escape_row row["code"]}','#{self.escape_row row["title"]}','#{self.escape_row row["article"]}','#{price_id}')"
      end
      query = query_string + values.join(",")
      @db.aquery(query, :async => true)
  end
end