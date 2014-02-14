# Загальний клас для баз даних
require 'em-mysqlplus'
require 'em-synchrony'

class NonBlockingDB
  def initialize db
    set_db db
  end
  def set_db(db)
    config = "config.yaml"
    config = File.join(File.dirname(__FILE__),config) unless File.exists? config
    @config = YAML.load_file(config)["development"]
    @db = EventMachine::Synchrony::ConnectionPool.new(:size => @config["concurrency"]["pool_size"]) do
      Mysql2::EM::Client.new(@config["db"][db])
    end
  end
  def get_db
    @db
  end
end



  
