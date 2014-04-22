require_relative 'lib/utm_mapper'
require 'rspec/core/rake_task'
require 'rake/notes/rake_task'

FileUtils.cd 'lib/', :verbose => true
@mapper = Mapper::Base.new

desc 'Run'
task :run do
  @mapper.run
end

desc 'Setup storage'
task :setup_storage do
  @mapper.setup_storage
end

task :hello do
  p "Hello Rake!"
  puts "Current env is #{ENV['MAPPER_ENV']}"
end

desc 'Test'
task :spec, :arg do |t, args|
  (args[:arg].nil?) ? con = "*" : con = args[:arg]
  p con
  RSpec::Core::RakeTask.new do |q|
    path = "../spec/#{con}_spec.rb"
    q.pattern = FileList[path]
  end
end

desc 'Starts Solr'
task :start_solr do
  if @mapper.search_worker.server_running?
    @mapper.print "Solr is running"
  else
    @mapper.start_search_server
  end
end

desc 'Stops Solr'
task :stop_solr do
	@mapper.stop_search_server if @mapper
end

desc 'starts webserver'
task :start_webserver do
  @mapper.start_webserver
end
task :stop_webserver do
  @mapper.stop_webserver
end

task :default => :spec
