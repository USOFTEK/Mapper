# Загальний клас для баз даних
require 'em-mysqlplus'
require 'em-synchrony'

class DB
  def initialize db
    set_db db
  end
  def set_db(db)
    @config = YAML.load_file('config.yaml')["development"] if @config.nil?
    @db = EventMachine::Synchrony::ConnectionPool.new(:size => @config["concurrency"]["pool_size"]) do
      Mysql2::EM::Client.new(@config["db"][db])
    end
  end
  def get_db
    @db
  end
end



  