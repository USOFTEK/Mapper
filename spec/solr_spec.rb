require_relative 'spec_helper'

describe 'Solr' do
  include EventedSpec::SpecHelper
  include EventedSpec::AMQPSpec
  
  default_timeout 120
  before :all do
    done
  end
  it 'checks java' do
    stdin, stdout,stderr = Open3.popen3("java -version")
    expect(stderr.readlines[0]).to match /java version \"?1.[6-9]/
    done
  end
  it 'runs search server and stops it' do
    expect(Dir.exists? '../solr/example/example-DIH/solr/').to be_true
       
    @mapper.start_search_server
    EM.add_timer(17){
      p "IS RUNNING? " + @solr.server_running?.to_s
      expect(@solr.server_running?).to be_true
      expect(@solr.get_total_docs).to be_a_kind_of Integer
      expect(@solr.get_total_docs).to be > 0
      done
      #@mapper.stop_search_server
      #EM.add_timer(1){
      #p "IS RUNNING? " + @solr.server_running?.to_s
      # expect(@solr.server_running?).to be_false
      # done
      #}
    }
  end
  it 'removes index' do
    EM.add_timer(30) do
      expect(@solr.server_running?).to be_true
      expect(@solr.remove_index).to be_true
      expect(@solr.get_total_docs).to eq 0
      done
    end
  end
  it 'fullimport' do
    
    EM.add_timer(35) do
      expect(@solr.server_running?).to be_true
      expect(@solr.remove_index).to be_true
      expect(@solr.get_total_docs).to eq 0
   
      @solr.index
      EM.add_periodic_timer(5){
        status = @solr.check_index["status"]
        p status
        if status == "idle"
          p "Ola! I've finished"
          p "status: #{status}"
          expect(@solr.get_total_docs).to eq 69504
          done
        else
          p "Don't bother me.. I'm still #{status}"
        end
      }
    end
  end
end
