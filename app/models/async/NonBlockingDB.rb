# Загальний клас для баз даних
require 'em-synchrony'

class NonBlockingDB
  def initialize db
    set_db db
  end
  def check_filename filename
    (File.exists?(filename)) ? filename : File.join(File.dirname(__FILE__),filename)
  end
  def set_db(db)
    config = "../../../config/config.yaml"
    @config = YAML.load_file(check_filename config)["development"]
    @db = EventMachine::Synchrony::ConnectionPool.new(:size => @config["concurrency"]["pool_size"]) do
      Mysql2::EM::Client.new(@config["db"][db])
    end
  end
  def get_db
    @db
  end
  def count
      Fiber.new{@db.query("SELECT COUNT(*) FROM `#{@db_name}`", :as => :array, :async => false).each{|row| row}[0][0]}.resume
  end
  def is_empty?
    Fiber.new{count == 0}.resume
  end
end



  
