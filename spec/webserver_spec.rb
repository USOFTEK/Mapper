require_relative 'spec_helper'
#TODO: допрацювати виключення сервера проблема з Sinatra
describe 'WebServer' do
  include EventedSpec::SpecHelper
  include EventedSpec::EMSpec
  
  default_timeout 20
  let(:host){'localhost'}
  let(:port){4567}
  
  it 'runs webserver and checks main routes' do
    EM.defer{@pm.start_webserver}
    EM.add_timer(1){
      EM.defer{
        ['/', '/link'].each do |path|
          response = Net::HTTP.get_response(host, path, port)
          code = response.code.to_i
          p response
          p "Path: #{path} - code: #{code}"
          expect(code).to eq 200
        end
        done
      }
    }
  end
end
