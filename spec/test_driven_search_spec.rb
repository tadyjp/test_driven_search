require 'elasticsearch'
require 'test_driven_search'

describe TestDrivenSearch do

  before do
    @client = Elasticsearch::Client.new host: 'localhost:9200'

    if @client.indices.exists index: 'japanese-text-test'
      @client.indices.delete index: 'japanese-text-test'
    end

    @client.indices.create index: 'japanese-text-test', body: {
      settings: {
        index: {
          number_of_shards: 1,
          number_of_replicas: 0,
          store: { type: 'memory' },
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
        test_index: {
          properties: {
            id:    {type: 'integer'},
            title: {type: 'string', analyzer: 'ngram_analyzer'},
            body:  {type: 'string', analyzer: 'kuromoji_analyzer'},
          }
        }
      }
    }

    @client.index index: 'japanese-text-test', type: 'test_index', body: {
      id: 1001,
      title: 'ruby is my favorite language.',
      body:  'rubyは私の好きな言語です',
    }
    @client.index index: 'japanese-text-test', type: 'test_index', body: {
      id: 1002,
      title: 'java...',
      body:  'javaはあまり得意ではありません',
    }
    @client.indices.refresh index: 'japanese-text-test'
  end

  describe '#test_a' do
    it { expect(TestDrivenSearch.test_a).to eq(123) }
    it { expect(TestDrivenSearch.test_a).not_to eq(9123) }
  end

  describe '#search_by_body' do
    res_ids = TestDrivenSearch.search_by_body('ruby').map{|i| i['_source']['id']}
    it { expect(res_ids).to include(1001) }
    it { expect(res_ids).not_to include(1002) }
  end

end
