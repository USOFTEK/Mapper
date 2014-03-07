require_relative 'spec_helper'

describe Mapper::Base do
 
  include EventedSpec::SpecHelper
  include EventedSpec::AMQPSpec
  
  default_timeout 5
  
  it 'checks if reactor is running' do
    expect(@mapper).to receive(:set_output).with(@output).and_call_original
    expect(@mapper).to receive(:run).and_call_original
    @mapper.set_output(@output)
    done {
      @mapper.run
      done {
        expect(@output.string).to include "run"
        done
      }
    }
  end
end

