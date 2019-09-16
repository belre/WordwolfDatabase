


require 'active_record'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(:development)


class Contents < ActiveRecord::Base
end


names = Contents.all
names.each do |element|
	puts element.name + "\t" 
end






