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
end



  
