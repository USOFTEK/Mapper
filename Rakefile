require_relative 'lib/utm_mapper'
require 'rspec/core/rake_task'

FileUtils.cd 'lib/', :verbose => true
@mapper = Mapper::Base.new

desc 'Run'
task :run do
  @mapper.run
end
task :hello do
  p "Hello Rake!"
end
desc 'Test'
task :spec do
  spec = RSpec::Core::RakeTask.new do |t|
    t.pattern = FileList['../spec/*_spec.rb']
  end
end

desc 'Starts Solr'
task :start_solr do
	@mapper.start_search_server
end

desc 'Stops Solr'
task :stop_solr do
	@mapper.stop_search_server if @mapper
end

task :default => :spec