# require 'hashie'

module TestDrivenSearch

  def self.search_by_body(_body)
    client = Elasticsearch::Client.new host: 'localhost:9200', log: true
    response = client.search :index => 'japanese-text-test', body: {
      query: { match: { _all: _body } }
    }
    response['hits']['hits']
  end
end
