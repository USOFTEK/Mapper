require_relative 'lib/utm_mapper'
require 'rspec/core/rake_task'

FileUtils.cd 'lib/', :verbose => true
@mapper = Mapper::Base.new

desc 'Run'
task :run do
  @mapper.run
end

task :my_task, :arg1, :arg2 do |t, args|
  puts "Args were: #{args}"
end

desc 'Setup storage'
task :setup_storage do
  @mapper.setup_storage
end

task :hello do
  p "Hello Rake!"
  puts "Current env is #{ENV['RAKE_ENV']}"
end

task :ordered_tests do 
  RSpec::Core::RakeTask.new do |q|
    q.spec_files = FileList['solr_spec.rb', 'webserver_spec.rb', 'mapper_spec.rb', 'price_manager_spec.rb', 'amqp_spec.rb']
  end
end
desc 'Test'
task :spec, :arg do |t, args|
  (args[:arg].nil?) ? con = "*" : con = args[:arg]
  RSpec::Core::RakeTask.new do |q|
    path = "../spec/#{con}_spec.rb"
    p path
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
