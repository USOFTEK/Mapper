#module Mapper
require 'em-synchrony'
require 'em-synchrony/mysql2'
require 'em-synchrony/fiber_iterator'
require 'amqp'
require 'fiber'
require 'yaml'
require 'logging'

require_relative 'PriceReader'
require_relative 'SearchWorker'
require_relative 'PriceManager'
require_relative 'models/Product'
require_relative 'models/async/NonBlockingDB'
require_relative 'models/async/StorageItem'
require_relative 'models/async/StoragePrice'
require_relative 'models/async/StorageComparison'
require_relative 'models/async/ShopItem'
require_relative 'WebServer'



  
#end
#PriceManager.new({:dir=>"prices/test", :env => 'development'}).start
