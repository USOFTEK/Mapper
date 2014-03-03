require_relative 'spec_helper'

describe Mapper::Base do
 
  include EventedSpec::SpecHelper
  include EventedSpec::AMQPSpec
  
  default_timeout 360
  
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
    #it 'matches products and stores in db' do
    #  expect(@solr.server_running?).to be_true
    #  Comparison.delete_all
    #  expect(Comparison.count).to eq 0
    #  Fiber.new{@pm.match}.resume
    #  EM.add_timer(280){
    #    expect(Comparison.count).to eq 9400
    #    done
    #  }
    #end
end

