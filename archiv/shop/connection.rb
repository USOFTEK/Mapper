require "em-synchrony/activerecord"
require "yaml"

def config
	config = YAML.load_file('../../config.yaml')["development"]["db"]["shop"]
end
