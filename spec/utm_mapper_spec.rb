require_relative 'spec_helper'
require_relative '../lib/utm_mapper'

require 'rspec/mocks'
require 'evented-spec'
require 'fiber'
require 'open3'


describe Mapper::Base do
 
  include EventedSpec::SpecHelper
  include EventedSpec::AMQPSpec
  
  default_timeout 360
	before :all do
    @output = StringIO.new
    @mapper = Mapper::Base.new
    @pm = PriceManager.new
    done
	end
 
  let(:data) { "Rspec welcomes you!" }
  
  it 'checks if reactor is running' do
    
    expect(@mapper).to receive(:set_output).with(@output).and_call_original
    expect(@mapper).to receive(:run).and_call_original
    
    @mapper.set_output(@output)
    done {
      @mapper.run
      done {
        expect(@output.string).to include "run" #match(/.*run!/)
        done
      }
    }
  end
  it "tests amqp broker" do
    AMQP::Channel.new do |channel|
      exchange = channel.direct("amqp.default.exchange")
      queue = channel.queue("test").bind(exchange)
      queue.subscribe do |hdr, msg|
        expect(hdr).to be_an AMQP::Header
        expect(msg).to eq data
        p data
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
  describe "PriceManager" do
    before :all do
      @filenames = @pm.get_price_names
      @dictionary = @pm.dictionary["headers"]
      @solr = @pm.search_worker
    end
    it 'checks prices existance' do
      expect(@filenames).to be_a_kind_of Array
      expect(@filenames.count).to be >= 1
      done
    end
    
    #it 'PriceReader#parse' do
    # @filenames.each do |filename| 
    #   price_reader = PriceReader.new(filename, @dictionary)
    #   expect(price_reader).to receive(:parse).and_call_original
    #   data = price_reader.parse
    #   expect(data).to be_a_kind_of Hash
    #   expect(data[:results]).to be_a_kind_of Array
    #   expect(data[:results].count).to be >= 100
    #   expect(data[:headers]).to be_a_kind_of Hash
    #   expect(data[:headers]["title"]).to be_a_kind_of Hash
    #   expect(data[:line]).to be_a_kind_of Integer
    #  p "Filename: #{filename} has count: #{data[:results].count}"
    #end
    #delayed(1){done}
    #end
    it 'matches products and stores in db' do
      #1. Видаляємо існуючі записи @storage_comparison
      expect(@solr.server_running?).to be_true
      Fiber.new { @pm.storage_comparison.empty}.resume
      #EM.add_timer(0.3){expect(@pm.storage_comparison.is_empty?).to be_true}
        
      #3. Здійснюємо пошук
      EM.add_timer(1){
        Fiber.new{@pm.match}.resume
      }
      EM.add_timer(280){
        expect(@pm.storage_comparison.is_empty?).to be_false
        #5. Перевіряємо кіл-ть записаних даних
        done
      }
    end
    describe 'Solr' do
      #  it 'runs search server and stops it' do
      #    expect(Dir.exists? '../solr/example/example-DIH/solr/').to be_true
      # 
      #    stdin, stdout,stderr = Open3.popen3("java -version")
      #    expect(stderr.readlines[0]).to match /java version \"?1.[6-9]/
      #  
      #    @pm.start_search_server
      #    EM.add_timer(10){
      #      p "IS RUNNING? " + @solr.server_running?.to_s
      #      expect(@solr.server_running?).to be_true
      #      expect(@solr.get_total_docs).to be_a_kind_of Integer
      #      expect(@solr.get_total_docs).to be > 0
      #    
      #     @pm.stop_search_server
      #      EM.add_timer(1){
      #        p "IS RUNNING? " + @solr.server_running?.to_s
      #        expect(@solr.server_running?).to be_false
      #        done
      #      }
      #    }
      #  end
      #it 'removes index' do
      #  expect(@solr.remove_index).to be_true
      #  expect(@solr.get_total_docs[:count]).to eq 0
      #  done
      # end
      #it 'fullimport' do
      #  @solr.index
      #  EM.add_periodic_timer(5){
      #    status = @solr.check_index["status"]
      #    p status
      #    if status == "idle"
      #      p "Ola! I've finished"
      #      p "status: #{status}"
      #      expect(@solr.get_total_docs).to eq 69504
      #      done
      #    else
      #      p "Don't bother me.. I'm still #{status}"
      #    end
      #  }
      #end
      #it 'compares indexed products with stored' do
      #  # 1. Кількість записів у Shop database
      #  # 2. Порівняти кіль-ть документів в пошуковому сервері та базі
      #  shop =  ShopItem.new "shop"
      #  shop.all.callback do |data|
      #    p "Shop has #{data.count} products"
      #    p "Total count of indexed products #{@solr.get_total_docs}"
      #    expect(data.count).to eq @solr.get_total_docs
      #    done
      #  end
      #end
    end
    #TODO: допрацювати виключення сервера проблема з Sinatra
    describe 'WebServer' do
      #it 'runs webserver and stops it' do
      #  EM.defer{@pm.start_webserver}
      #    
      #  EM.add_timer(3){
      #    host = 'localhost'
      #    port = '4567'
      #    EM.defer{
      #      ['/', '/link'].each do |path|
      #        response = Net::HTTP.get_response(host, path, port)
      #        code = response.code.to_i
      #        p response
      #        p "Path: #{path} - code: #{code}"
      #        expect(code).to eq 200
      #      end
      #      done
      #    }
      #  }
      #EM.add_timer(3){
      #  @pm.stop_webserver
      #  EM.add_timer(5){
      #    EM.defer {
      #      expect(Net::HTTP.get_response(host, '/', port).code.to_i).to eq 403
      #      done
      #    }
      #  }
      #}
      #end
    end
  end
end

