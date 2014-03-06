class StoragePrice < NonBlockingDB
  def initialize db
    super db
  end
  def add(filename, hash)
    @db.aquery "INSERT INTO `prices` (`price`, `hash`) VALUES ('#{filename}', '#{hash}')"
  end
  def check(filename, hash)
    begin
      results = @db.query("SELECT price,hash FROM `prices` WHERE price = '#{filename}'", :as => :hash).each {|row|row}
      raise "Error", "Filenames duplicates have been found!" if results.length > 1
      return false if results.length == 0
      results[0]["hash"] == hash
    rescue => e
      p e
    end
  end
end
