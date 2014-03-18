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
    raise StandardError, "Mapper env is not defined!" if ENV['MAPPER_ENV'].nil?
    @config = YAML.load_file(check_filename config)[ENV['MAPPER_ENV']]
    @db = EventMachine::Synchrony::ConnectionPool.new(:size => @config["concurrency"]["pool-size"].to_i) do
      Mysql2::EM::Client.new(@config["db"][db])
    end
  end
  def get_db
    @db
  end
end



  
