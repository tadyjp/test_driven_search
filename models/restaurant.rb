require 'active_record'
require 'active_support'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection('development')

require 'elasticsearch'

class Restaurant < ActiveRecord::Base

  # ElasticSearchのHost
  def self.es_host
    'localhost:9200'
  end

  # index名
  def self.es_index_name
    'livedoor-gourmet'
  end

  # Restaurantモデルに紐づくtype名
  def self.es_type_name
    'restaurant'
  end

  # ElasticSearchクライアント
  def self.es_client
    @_es_client ||= Elasticsearch::Client.new host: es_host, log: true
  end

  # index refresh
  def self.es_refresh_index
    es_client.indices.refresh index: es_index_name
  end

  # index削除
  def self.es_delete_index
    if es_client.indices.exists index: es_index_name
      es_client.indices.delete index: es_index_name
    end
  end

  # indexの定義(Settings, Mappings)
  def self.es_create_index
    es_client.indices.create index: es_index_name, body: {
      settings: {
        index: {
          number_of_shards: 5,
          number_of_replicas: 1,
        },
        analysis: {
          tokenizer: {
            ngram_tokenizer: {
              type: 'nGram',
              min_gram: 2,
              max_gram: 3,
              token_chars: ['letter', 'digit']
            }
          },
          filter: {
          },
          analyzer: {
            ngram_analyzer: {
              type: 'custom',
              tokenizer: 'ngram_tokenizer',
              filter: ['lowercase', 'stop'],
            },
          }
        }
      },
      mappings: {
        restaurant: {
          _id: {path: 'id'},
          properties: {
            id:   {type: 'integer', index: 'not_analyzed'},
            name: {
              type: 'multi_field',
              fields: {
                name:       {type: 'string', analyzer: 'ngram_analyzer'},
                suggest:    {type: 'string', analyzer: 'kuromoji'},
                completion: {type: 'completion', analyzer: 'ngram_analyzer'},
              }
            },
            property:       {type: 'string', analyzer: 'ngram_analyzer'},
            alphabet:       {type: 'string', analyzer: 'ngram_analyzer'},
            name_kana:      {type: 'string', analyzer: 'ngram_analyzer'},
            pref_id:        {type: 'integer', index: 'not_analyzed'},
            category_ids:   {type: 'integer', index: 'not_analyzed'},
            zip:            {type: 'string', index: 'not_analyzed'},
            address:        {type: 'string', analyzer: 'kuromoji'},
            description:    {type: 'string', analyzer: 'kuromoji'},
          }
        }
      }
    }
  end


  def self.es_index_doc(_hash)
    es_client.index index: es_index_name, type: es_type_name, body: _hash
  end

  def self.es_index_restaurant(_restaurant)
    es_index_doc _restaurant.es_index_hash
  end

  def es_index_hash
    {
      id: self.id,
      name: self.name,
      property: self.property,
      pref_id: self.pref_id,
      category_ids: [self.category_id1, self.category_id2, self.category_id3, self.category_id4, self.category_id5].select{ |i| i > 0 },
      zip: self.zip,
      address: self.address,
      description: self.description
    }
  end

  def es_index
    self.class.es_index_doc(self.es_index_hash)
  end

  def self.search(_str)
    response = es_client.search :index => es_index_name, body: {
      query: {
        multi_match: {
          query: _str,
          fields: [
            "name^10",
            "address",
            "description"
          ],
        }
      },
      facets: {
        pref_id_facet: {
          terms: {
            field: 'pref_id',
            size: 10
          }
        },
        category_ids_facet: {
          terms: {
            field: 'category_ids',
            size: 10
          }
        }
      },
      suggest: {
        name_suggest: {
          text: _str,
          term: {
            field: 'name.suggest',
            size: 3
          }
        }
      },
      fields: ['id'],
      size: 100,
    }

    {
      ids: response['hits']['hits'].map{ |i| i['fields']['id'] }.flatten,
      suggests: response['suggest']['name_suggest'][0]['options'],
      response: response
    }
  end

  def self.completion(_str)
    response = es_client.search :index => es_index_name, body: {
      suggest: {
        name_completion: {
          text: _str,
          completion: {
            field: 'name.completion'
          }
        }
      }
    }

    response['suggest']['name_completion'][0]['options']
  end
end
