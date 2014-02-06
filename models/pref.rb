require 'active_record'
require 'active_support'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection('development')

class Pref < ActiveRecord::Base

end
