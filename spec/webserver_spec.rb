require_relative 'spec_helper'
#TODO: допрацювати виключення сервера проблема з Sinatra
describe 'WebServer' do
  include EventedSpec::SpecHelper
  include EventedSpec::AMQPSpec
  
  default_timeout 10
  it 'runs webserver and stops it' do
    EM.defer{@pm.start_webserver}
          
    EM.add_timer(3){
          host = 'localhost'
          port = '4567'
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
