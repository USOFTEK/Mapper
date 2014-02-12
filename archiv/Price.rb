class Price < DB
  def initialize db
    super db
  end
  def add filename
    @db.aquery "INSERT INTO `prices` (`price`) VALUES ('#{filename}')"
  end
  def check filename
    result = @db.query "SELECT price FROM `prices` WHERE price = '#{filename}'", :as => :array
    results = result.each {|row| row}
    results.length > 0
  end
end
