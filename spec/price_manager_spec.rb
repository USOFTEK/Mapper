require_relative 'spec_helper'

describe "PriceManager" do
  include EventedSpec::SpecHelper
  include EventedSpec::AMQPSpec
  
  default_timeout 60
  before :all do
    @filenames = @pm.get_price_names
    @dictionary = @pm.dictionary["headers"]
  end
  it 'checks prices existance' do
    expect(@filenames).to be_a_kind_of Array
    expect(@filenames.count).to be >= 1
    done
  end
    
  it 'parses prices and checks data' do
    @filenames.each do |filename| 
      price_reader = PriceReader.new(filename, @dictionary)
      expect(price_reader).to receive(:parse).and_call_original
      data = price_reader.parse
      expect(data).to be_a_kind_of Hash
      expect(data[:results]).to be_a_kind_of Array
      expect(data[:results].count).to be >= 100
      expect(data[:headers]).to be_a_kind_of Hash
      expect(data[:headers]["title"]).to be_a_kind_of Hash
      expect(data[:line]).to be_a_kind_of Integer
      p "Filename: #{filename} has count: #{data[:results].count}"
    end
    delayed(1){done}
  end
  it '#load_prices' do
    @pm.set_output(@output)
    Product.delete_all
    Price.delete_all
    expect(Product.count).to eq 0
    expect(Price.count).to eq 0
    Fiber.new{@pm.load_prices}.resume
    EM.add_timer(30){
      expect(@output.string).to include "Operation index has been successfully finished"
      done
    }
  end
end
