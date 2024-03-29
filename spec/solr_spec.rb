require_relative 'spec_helper'

describe 'Solr' do
  include EventedSpec::SpecHelper
  include EventedSpec::EMSpec
  
  default_timeout 100
  before :all do
    @start_delay = 0
  end
  it 'checks java' do
    stdin, stdout,stderr = Open3.popen3("java -version")
    expect(stderr.readlines[0]).to match /java version \"?1.[6-9]/
    done
  end
  it 'search server is running' do
    EM.add_timer(@start_delay + 1) do
      expect(@solr.server_running?).to be_true
      expect(@solr.get_total_docs).to be_a_kind_of Integer
      done
    end
  end
  it 'removes index' do
    EM.add_timer(@start_delay + 3) do
      expect(@solr.server_running?).to be_true
      expect(@solr.remove_index).to be_true
      expect(@solr.get_total_docs).to eq 0
      done
    end
  end
  it 'fullimport' do
    EM.add_timer(@start_delay + 6) do
      expect(@solr.server_running?).to be_true
      expect(@solr.remove_index).to be_true
      expect(@solr.get_total_docs).to eq 0
   
      @solr.index
      EM.add_periodic_timer(5){
        status = @solr.check_index["status"]
        p status
        if status == "idle"
          p "Ola! I've finished Full Import"
          p "status: #{status}"
          expect(@solr.get_total_docs).to be >= 50#eq 69504
          done
        else
          p "Full import in progress...I'm #{status}"
        end
      }
    end
  end
  it 'matches products and stores in db' do
    expect(@solr.server_running?).to be_true
    #expect(Product.count).to eq 9854
    expect(Price.count).to eq 2
    Comparison.delete_all
    expect(Comparison.count).to eq 0
    Fiber.new{@mapper.match}.resume
    EM.add_timer(10){
      expect(Comparison.count).to be >= 50#9000
      done
    }
  end
end
