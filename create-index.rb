require 'elasticsearch'
require 'pry'

client = Elasticsearch::Client.new host: 'localhost:9200', log: true

client.indices.create index: 'livedoor-gourmet', body: {
  settings: {
    index: {
      number_of_shards: 5,
      number_of_replicas: 0,
      # 'routing.allocation.include.name' => 'node-1',
      # store: { type: 'memory' },
    },
    analysis: {
      filter: {
        ngram_filter: {
          type: 'nGram',
          min_gram: 3,
          max_gram: 25
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
        pref_id:           {type: 'integer', index: 'not_analyzed'},
        area_id:           {type: 'integer', index: 'not_analyzed'},
        station_id1:       {type: 'integer', index: 'not_analyzed'},
        station_time1:     {type: 'integer', index: 'not_analyzed'},
        station_distance1: {type: 'integer', index: 'not_analyzed'},
        station_id2:       {type: 'integer', index: 'not_analyzed'},
        station_time2:     {type: 'integer', index: 'not_analyzed'},
        station_distance2: {type: 'integer', index: 'not_analyzed'},
        station_id3:       {type: 'integer', index: 'not_analyzed'},
        station_time3:     {type: 'integer', index: 'not_analyzed'},
        station_distance3: {type: 'integer', index: 'not_analyzed'},
        category_id1:      {type: 'integer', index: 'not_analyzed'},
        category_id2:      {type: 'integer', index: 'not_analyzed'},
        category_id3:      {type: 'integer', index: 'not_analyzed'},
        category_id4:      {type: 'integer', index: 'not_analyzed'},
        category_id5:      {type: 'integer', index: 'not_analyzed'},
        zip:               {type: 'string', index: 'not_analyzed'},
        address:           {type: 'string', analyzer: 'ngram_analyzer'},
        north_latitude:    {type: 'string', analyzer: 'ngram_analyzer'},
        east_longitude:    {type: 'string', analyzer: 'ngram_analyzer'},
        description:       {type: 'string', analyzer: 'ngram_analyzer'},
        purpose:           {type: 'string', analyzer: 'ngram_analyzer'},
        open_morning:      {type: 'string', analyzer: 'ngram_analyzer'},
        open_lunch:        {type: 'string', analyzer: 'ngram_analyzer'},
        open_late:         {type: 'string', analyzer: 'ngram_analyzer'},
        photo_count:       {type: 'integer', analyzer: 'ngram_analyzer'},
        special_count:     {type: 'integer', analyzer: 'ngram_analyzer'},
        menu_count:        {type: 'integer', analyzer: 'ngram_analyzer'},
        fan_count:         {type: 'integer', analyzer: 'ngram_analyzer'},
        access_count:      {type: 'integer', analyzer: 'ngram_analyzer'},
        created_on:        {type: 'date', format: 'YYYY-MM-dd HH:mm:ss'},
        modified_on:       {type: 'date', format: 'YYYY-MM-dd HH:mm:ss'},
        closed:            {type: 'integer', analyzer: 'ngram_analyzer'},
      }
    }
  }
}
