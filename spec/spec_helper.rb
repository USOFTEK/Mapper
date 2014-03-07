require_relative '../lib/utm_mapper'
require 'rspec/mocks'
require 'evented-spec'
require 'fiber'
require 'open3'
require "codeclimate-test-reporter"

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color_enabled = true 
  config.formatter = :documentation
  config.before(:all) do
    @output = StringIO.new
    @mapper = Mapper::Base.new
    @pm = PriceManager.new
    @solr = @pm.search_worker
  end
  config.order = 'defined'
end