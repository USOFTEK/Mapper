require_relative 'database'
require_relative 'migrations/CreatePrices'

raise ArgumentError, "No command passed" if ARGV[0].nil?
command = ARGV[0]
CreatePrices.migrate(command)


