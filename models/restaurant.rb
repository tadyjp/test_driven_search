require 'active_record'
require 'active_support'
require 'elasticsearch'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection('development')

class Restaurant < ActiveRecord::Base

  def self.es_host
    'localhost:9200'
  end

  def self.es_index_name
    'livedoor-gourmet'
  end

  def self.es_type_name
    'restaurant'
  end

  def self.es_client
    @_es_client ||= Elasticsearch::Client.new host: es_host, log: true
  end

  def self.es_delete_index
    if es_client.indices.exists index: es_index_name
      es_client.indices.delete index: es_index_name
    end
  end

  def self.es_create_index
    es_client.indices.create index: es_index_name, body: {
      settings: {
        index: {
          number_of_shards: 5,
          number_of_replicas: 1,
          # 'routing.allocation.include.name' => 'node-1',
          # store: { type: options[:in_memory] ? 'memory' : nil },
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
            kuromoji_analyzer: {
              type: 'custom',
              tokenizer: 'kuromoji_tokenizer',
              # filter: ['kuromoji_baseform', 'pos_filter', 'greek_lowercase_filter', 'cjk_width']
              filter: ['kuromoji_baseform', 'kuromoji_readingform'],
            },
          }
        }
      },
      mappings: {
        restaurant: {
          _id: {path: 'id'},
          properties: {
            id:                {type: 'integer', index: 'not_analyzed'},
            # name:              {type: 'string', analyzer: 'ngram_analyzer'},

            # うまくsearch analyzerが設定できない...
            name: {
              type: 'multi_field',
              # path: 'address2',
              fields: {
                ngram:    {type: 'string', analyzer: 'ngram_analyzer'},
                kuromoji: {type: 'string', analyzer: 'kuromoji'},
              }
            },

            name_completion: {type: 'completion', analyzer: 'kuromoji'},

            # name_ngram:        {type: 'string', analyzer: 'ngram_analyzer'},
            # name_kuromoji:     {type: 'string', analyzer: 'kuromoji'},

            property:          {type: 'string', analyzer: 'ngram_analyzer'},
            alphabet:          {type: 'string', analyzer: 'ngram_analyzer'},
            name_kana:         {type: 'string', analyzer: 'ngram_analyzer'},
            pref_id:           {type: 'integer', index: 'not_analyzed'},
            # area_id:           {type: 'integer', index: 'not_analyzed'},
            # station_id1:       {type: 'integer', index: 'not_analyzed'},
            # station_time1:     {type: 'integer', index: 'not_analyzed'},
            # station_distance1: {type: 'integer', index: 'not_analyzed'},
            # station_id2:       {type: 'integer', index: 'not_analyzed'},
            # station_time2:     {type: 'integer', index: 'not_analyzed'},
            # station_distance2: {type: 'integer', index: 'not_analyzed'},
            # station_id3:       {type: 'integer', index: 'not_analyzed'},
            # station_time3:     {type: 'integer', index: 'not_analyzed'},
            # station_distance3: {type: 'integer', index: 'not_analyzed'},
            category_ids:      {type: 'integer', index: 'not_analyzed'},
            zip:               {type: 'string', index: 'not_analyzed'},
            address:     {
              type: 'multi_field',
              # path: 'address2',
              fields: {
                ngram:    {type: 'string', analyzer: 'ngram_analyzer'},
                kuromoji: {type: 'string', analyzer: 'kuromoji'},
              }
            },
            # north_latitude:    {type: 'string', analyzer: 'ngram_analyzer'},
            # east_longitude:    {type: 'string', analyzer: 'ngram_analyzer'},
            description:       {type: 'string', analyzer: 'ngram_analyzer'},
            # purpose:           {type: 'string', analyzer: 'ngram_analyzer'},
            # open_morning:      {type: 'string', analyzer: 'ngram_analyzer'},
            # open_lunch:        {type: 'string', analyzer: 'ngram_analyzer'},
            # open_late:         {type: 'string', analyzer: 'ngram_analyzer'},
            # photo_count:       {type: 'integer', analyzer: 'ngram_analyzer'},
            # special_count:     {type: 'integer', analyzer: 'ngram_analyzer'},
            # menu_count:        {type: 'integer', analyzer: 'ngram_analyzer'},
            # fan_count:         {type: 'integer', analyzer: 'ngram_analyzer'},
            # access_count:      {type: 'integer', analyzer: 'ngram_analyzer'},
            # created_on:        {type: 'date', format: 'YYYY-MM-dd HH:mm:ss'},
            # modified_on:       {type: 'date', format: 'YYYY-MM-dd HH:mm:ss'},
            # closed:            {type: 'integer', analyzer: 'ngram_analyzer'},
          }
        }
      }
    }
  end

  def self.es_refresh_index
    es_client.indices.refresh index: es_index_name
  end

  def self.es_index_doc(_hash)
    _hash[:name_completion] = _hash[:name] # オートコンプリート用

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
            "name.kuromoji^10",
            "name.ngram^5",
            "address.kuromoji^2",
            "address.ngram"
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
            field: 'name.kuromoji',
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
    # {
    #   ids: response['hits']['hits'].map{ |i| i['_source']['id'] },
    #   hits: response['hits'],
    #   facets: response['facets'],
    # }
  end

  # def self.suggest(_str)
  #   response = es_client.search :index => es_index_name, body: {
  #     suggest: {
  #       name_suggest: {
  #         text: _str,
  #         term: {
  #           field: 'name.kuromoji'
  #         }
  #       }
  #     }
  #   }

  #   response['suggest']['name_suggest'][0]['options']
  # end

  def self.completion(_str)
    response = es_client.search :index => es_index_name, body: {
      suggest: {
        name_completion: {
          text: _str,
          completion: {
            field: 'name_completion'
          }
        }
      }
    }

    response['suggest']['name_completion'][0]['options']
  end
end
