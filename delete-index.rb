require 'elasticsearch'
require 'pry'

client = Elasticsearch::Client.new host: 'localhost:9200', log: true

client.indices.delete index: 'livedoor-gourmet'
