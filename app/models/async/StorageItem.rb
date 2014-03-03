class StorageItem < NonBlockingDB
  attr_reader :db
  def initialize db
    super db
    @db_name = "products"
  end
  def escape_row(row)
    @db.escape row || "NULL"
  end
  def all
    @db.query("SELECT id,title,code,article FROM `#{@db_name}`", :as => :hash, :async => false).each {|row| row}
  end 
  def add(data, filename)
   
      price_id = @db.last_id
      values = []
      query_string =  "INSERT INTO `#{@db_name}` (`code`, `title`, `article`, `price_id`) VALUES "
      data[:results].each do |row|
        values << "('#{self.escape_row row["code"]}','#{self.escape_row row["title"]}','#{self.escape_row row["article"]}','#{price_id}')"
      end
      query = query_string + values.join(",")
      @db.aquery(query)
  end
end
