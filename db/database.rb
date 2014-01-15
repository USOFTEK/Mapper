require 'active_record'
require 'mysql2/em'

ActiveRecord::Base.establish_connection(
	adapter: 'mysql2',
	host: 'localhost',
	username: 'root',
	password: '238457',
	database: 'test',
  checkout_timeout: 60,
  dead_connection_timeout: 120,
  pool: 20
)
