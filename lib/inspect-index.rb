require 'elasticsearch'
require 'yaml'

client = Elasticsearch::Client.new host: 'localhost:9200', log: true

puts client.indices.get_settings(index: 'livedoor-gourmet').to_yaml
puts client.indices.get_mapping(index: 'livedoor-gourmet').to_yaml
