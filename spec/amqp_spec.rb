require_relative 'spec_helper'

describe "AMQP broker" do
  include EventedSpec::SpecHelper
  include EventedSpec::AMQPSpec
  
  default_timeout 10
  let(:data) { {:foo => "Rspec welcomes you!"} }

  it "tests amqp broker" do
    AMQP::Channel.new do |channel|
      exchange = channel.direct("amqp.default.exchange")
      queue = channel.queue("test").bind(exchange)
      queue.subscribe do |hdr, msg|
        expect(hdr).to be_an AMQP::Header
        expect(eval(msg)).to eq data
        p msg
        done { queue.unsubscribe; queue.delete }
      end
      EM.add_timer(0.2) do
        exchange.publish data
      end
    end
  end
  it 'sends a message to amqp broker' do
    channel = AMQP::Channel.new
    queue = channel.queue("rabbit.mapper", :auto_delete => true)
    exchange = channel.default_exchange
    exchange.publish(data, :routing_key => queue.name)
    delayed(0.2) do
      done { queue.unsubscribe; queue.delete }
    end
  end
end
