require_relative 'spec_helper'

describe 'WebServer' do
  include EventedSpec::SpecHelper
  include EventedSpec::EMSpec
  
  default_timeout 20
  let(:host){'http://localhost'}
  let(:port){4567}
  
  it 'checks main routes' do
    EM.add_timer(2){
      ['/', '/link'].each do |path|
        req = EventMachine::HttpRequest.new("#{host}:#{port}#{path}").get
        req.callback {
          p "Finished? #{req.finished?}"
          expect(req.finished?).to be_true
        }
      end
    }
    EM.add_timer(5){done}
  end
end
