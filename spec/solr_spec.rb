require_relative 'spec_helper'

describe 'Solr' do
  include EventedSpec::SpecHelper
  include EventedSpec::EMSpec
  
  default_timeout 600
  before :all do
    @start_delay = 2
  end
  it 'checks java' do
    stdin, stdout,stderr = Open3.popen3("java -version")
    expect(stderr.readlines[0]).to match /java version \"?1.[6-9]/
    done
  end
  it 'runs search server and stops it' do
    @start_delay = 0.5
   unless @solr.server_running?
     @start_delay = 20 
     @mapper.start_search_server
   end
    p @start_delay
    EM.add_timer(@start_delay){
      expect(Dir.exists? '../solr/example/example-DIH/solr/').to be_true
      EM.add_timer(1){
        p "IS RUNNING? " + @solr.server_running?.to_s
        expect(@solr.server_running?).to be_true
        expect(@solr.get_total_docs).to be_a_kind_of Integer
        done
      }
    }
  end
  it 'removes index' do
    p @start_delay
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
          expect(@solr.get_total_docs).to eq 69504
          done
        else
          p "Full import in progress...I'm #{status}"
        end
      }
    end
  end
  it 'matches products and stores in db' do
      expect(@solr.server_running?).to be_true
      expect(Product.count).to eq 9854
      expect(Price.count).to eq 5
      Comparison.delete_all
      expect(Comparison.count).to eq 0
      Fiber.new{@mapper.match}.resume
      EM.add_timer(500){
        expect(Comparison.count).to be >= 9000
        done
      }
    end
end
