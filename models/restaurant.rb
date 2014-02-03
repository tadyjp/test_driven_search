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
    @_es_client ||= Elasticsearch::Client.new host: es_host
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
          number_of_replicas: 0,
          # 'routing.allocation.include.name' => 'node-1',
          # store: { type: options[:in_memory] ? 'memory' : nil },
        },
        analysis: {
          filter: {
            ngram_filter: {
              type: 'nGram',
              min_gram: 1,
              max_gram: 4
            }
          },
          analyzer: {
            ngram_analyzer: {
              type: 'custom',
              tokenizer: 'whitespace',
              filter: ['lowercase', 'stop', 'ngram_filter'],
            },
            ngram_search: {
              type: 'custom',
              tokenizer: 'whitespace',
              filter: ['lowercase', 'stop'],
            },
            kuromoji_analyzer: {
              type: 'custom',
              tokenizer: 'kuromoji_tokenizer',
              # filter: ['kuromoji_baseform', 'pos_filter', 'greek_lowercase_filter', 'cjk_width']
              filter: ['kuromoji_baseform'],
            },
          }
        }
      },
      mappings: {
        restaurant: {
          _id: {path: 'id'},
          properties: {
            id:                {type: 'integer', analyzer: 'ngram_analyzer'},
            name:              {type: 'string', analyzer: 'ngram_analyzer'},
            property:          {type: 'string', analyzer: 'ngram_analyzer'},
            alphabet:          {type: 'string', analyzer: 'ngram_analyzer'},
            name_kana:         {type: 'string', analyzer: 'ngram_analyzer'},
            # pref_id:           {type: 'integer', index: 'not_analyzed'},
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
            # category_id1:      {type: 'integer', index: 'not_analyzed'},
            # category_id2:      {type: 'integer', index: 'not_analyzed'},
            # category_id3:      {type: 'integer', index: 'not_analyzed'},
            # category_id4:      {type: 'integer', index: 'not_analyzed'},
            # category_id5:      {type: 'integer', index: 'not_analyzed'},
            # zip:               {type: 'string', index: 'not_analyzed'},
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
            # description:       {type: 'string', analyzer: 'ngram_analyzer'},
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
    es_client.index index: es_index_name, type: es_type_name, body: _hash
  end

  def self.es_index_restaurant(_restaurant)
    es_index_doc _restaurant.es_index_hash
  end

  def es_index_hash
    self.attributes.slice('id', 'name', 'property', 'alphabet', 'name_kana', 'pref_id', 'area_id', 'station_id1', 'station_time1', 'station_distance1', 'station_id2', 'station_time2', 'station_distance2', 'station_id3', 'station_time3', 'station_distance3', 'category_id1', 'category_id2', 'category_id3', 'category_id4', 'category_id5', 'zip', 'address', 'north_latitude', 'east_longitude', 'description', 'purpose', 'open_morning', 'open_lunch', 'open_late', 'photo_count', 'special_count', 'menu_count', 'fan_count', 'access_count', 'created_on', 'modified_on', 'close')
  end

  def es_index
    self.class.es_index_docs(self)
  end

  def self.search(_str)
    response = es_client.search :index => es_index_name, body: {
      query: { match: { _all: _str } }
    }
    response['hits']['hits'].map{|i| i['_source']['id']}
  end

end
