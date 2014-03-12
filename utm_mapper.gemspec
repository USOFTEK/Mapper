Gem::Specification.new do |s|
  s.name        = 'utm_mapper'
  s.version     = '0.1.1'
  s.licenses    = ['MIT']
  s.summary     = "Mapper summary"
  s.description = "Much longer explanation of summary"
  s.authors     = ["Nychka Yaroslav"]
  s.email       = 'nychka08@yandex.ru'
  #s.files       = ["lib/utm_mapper_new.rb", "lib/PriceManager.rb", "lib/PriceReader.rb", "lib/SearchWorker.rb"]
  s.files = Dir['lib/*.rb'] + Dir['config/*.yaml'] + Dir['app/models/*.rb'] + Dir['app/models/async/*.rb'] + Dir['app/views/*.erb'] + Dir['app/assets/stylesheets/*.css'] + Dir['app/assets/javascripts/*.js']
  s.homepage    = 'https://rubygems.org/gems/example'
  s.post_install_message = "Thanks for installing!"
  s.requirements << "mysql2"
  s.requirements << "active_record"
  s.requirements << "eventmachine"
  s.requirements << "em-synchrony"
  s.requirements << 'amqp'
  s.requirements << 'fiber'
  s.requirements << 'yaml'
  s.requirements << 'logging'
  s.requirements << "rsolr"
  s.requirements << "rsolr-ext"
  s.requirements << "sinatra"
  s.requirements << "simple-spreadsheet"
end

