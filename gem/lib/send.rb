require 'amqp'

AMQP.start do |connection|
	puts "Sending is started.."
	channel = AMQP::Channel.new connection
	queue = channel.queue(ARGV[0], :auto_delete => true)
	#exchange = channel.direct("default")
	#queue.bind exchange
	exchange = channel.default_exchange
	exchange.publish(ARGV[1], :routing_key => queue.name)
end
