#module Mapper
require 'em-synchrony'
require 'em-synchrony/mysql2'
require 'em-synchrony/fiber_iterator'
require 'amqp'
require 'fiber'
require 'yaml'
require 'logging'

require_relative 'PriceReader'
require_relative 'lib/Search'
require_relative 'PriceManager'
require_relative 'lib/models/Product'
require_relative 'lib/models/async/NonBlockingDB'
require_relative 'lib/models/async/StorageItem'
require_relative 'lib/models/async/StoragePrice'
require_relative 'lib/models/async/StorageComparison'
require_relative 'lib/models/async/ShopItem'
require_relative 'lib/WebServer'



  
#end
PriceManager.new({:dir=>"prices/test", :env => 'development'}).start
