require_relative 'spec_helper'

describe "PriceManager" do
  include EventedSpec::SpecHelper
  include EventedSpec::EMSpec
  
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
    expect(@filenames.count).to be > 0
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
  it 'checks hashes' do
    expect(@pm.get_price_names.count).to be > 0
    @pm.get_price_names.each do |price|
      p price
      case price
      when 'kt.xlsx'
        expect(@pm.get_hash(price)).to eq "386e386a31b984a7cec65d929b051be649915f0d6a3e46180ffa7e46535c2358"
      when 'ktc.xlsx'
        expect(@pm.get_hash(price)).to eq "470f2de98ec0649be8a6cc991f7e6e1494abb460b117ee4baa2c16f789dde9cc"
      when 'price_minimal.xlsx'
        expect(@pm.get_hash(price)).to eq "b173b3fce19330c3749cdc801f6d5e621f6329e401ba58f2805713c280adea7f"
      when 'opt.xlsx'
        expect(@pm.get_hash(price)).to eq "947cfdaefa180561b1072662dab68a507ceebaca36f700354ad6c514aa2d96c4"
      when 'Pr1.xlsx'
        expect(@pm.get_hash(price)).to eq "d0342860ada51bfc80d40db8f61c78e84c1b60e23da7a1c43b6f329c37b95974"
      end
    end
    done
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
      Fiber.new{@pm.load_prices}.resume
      EM.add_timer(5){
        expect(@output.string).to include "already exists in database!"
        done
      }
    }
  end
end
