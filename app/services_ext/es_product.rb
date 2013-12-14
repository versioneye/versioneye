class EsProduct

  def self.create_index_with_mappings
    Tire.index Settings.elasticsearch_product_index do
      create :settings => {
          :number_of_shards => 1,
          :number_of_replicas => 1,
          :analysis => {
            :filter => {
              :name_ngrams => {
                :side => 'front',
                :type => 'edgeNGram',
                :max_gram => 100,
                :min_gram => 2
              }
            },
            :analyzer => {
              :product_name => {
                :filter => ['standard', 'lowercase', 'asciifolding'],
                :type => 'custom',
                :tokenizer => 'standard'
              },
              :ngram_name => {
                :filter => ['standard', 'lowercase', 'asciifolding', 'name_ngrams'],
                :type => 'custom',
                :tokenizer => 'standard'
              }
            }
          }
        },
      :mappings => {
        :product => {
          :properties => {
            :_id  => { :type => 'string', :analyzer => 'keyword', :include_in_all => false },
            :name => { :type => 'multi_field', :fields => {
                :name    => {:type => 'string', :analyzer => 'product_name', :include_in_all => false},
                :partial => {
                  :search_analyzer => 'product_name',
                  :index_analyzer  => 'ngram_name',
                  :type => 'string',
                  :include_in_all => true,
                  :boost => 10
                }
              }
            },
            :followers          => { :type => 'integer', :include_in_all => true},
            :used_by_count      => { :type => 'integer', :include_in_all => true},
            :description        => { :type => 'string', :analyzer => 'snowball' },
            :description_manual => { :type => 'string', :analyzer => 'snowball' },
            :language           => { :type => 'string', :analyzer => 'keyword'  }
          }
        }
      }
    end
  end

  def self.clean_all
    Tire.index( Settings.elasticsearch_product_index ).delete
  end

  def self.reset
    self.clean_all
    self.create_index_with_mappings
  end

  def self.index_all
    Product.all.each do |product|
      index product
    end
    self.refresh
  end

  def self.index( product )
    Rails.logger.info "index #{product.name}"
    Tire.index Settings.elasticsearch_product_index do
      store product.to_indexed_json
      product.update_attribute(:reindex, false)
    end
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end

  def self.refresh
    Tire.index( Settings.elasticsearch_product_index ).refresh
  end

  def self.index_and_refresh( product )
    self.index product
    self.refresh
  end

  def self.index_newest
    Product.where(reindex: true).each do |product|
      index product
    end
    self.refresh
    Product.where(reindex: nil).each do |product|
      index product
    end
    self.refresh
  end

  def self.remove( product )
    Tire.index( Settings.elasticsearch_product_index ).remove( product.id )
  end

  # langs: need to be an Array !
  # page_count: has to start by 1. Not by 0!
  #
  def self.search(q, group_id = nil, langs = Array.new, page_count = 1)
    if (q.nil? || q.empty?) && (group_id.nil? || group_id.empty?)
      raise ArgumentError, "query and group_id are both empty! This is not allowed"
    end

    page_count = 1 if page_count.nil? || page_count.to_i < 1
    results_per_page = 30
    from = results_per_page * (page_count.to_i - 1)

    group_id = "" if !group_id

    q = "*" if !q || q.empty?
    q.downcase

    s = Tire.search( Settings.elasticsearch_product_index,
                      load: true,
                      from: from,
                      search_type: "dfs_query_and_fetch",
                      per_page: results_per_page,
                      size: results_per_page) do |search|

      if langs and !langs.empty?
        decoded_langs = []
        langs.each do |lang|
          decoded_langs << Product.decode_language(lang)
        end
        search.filter :terms, :language => decoded_langs
      end

      search.query do |query|
        if q != '*' and !group_id.empty?
          # when user search by name and group_id
          query.boolean do
            must {string 'name.partial:' + q}
            must {string 'group_id:' + group_id + "*"}
          end
        elsif q != '*' and group_id.empty?
          query.custom_score :script => "(_score + doc['used_by_count'].value) * (doc['followers'].value + 1)" do
            string "name.partial:" + q
          end
        elsif q == '*' and !group_id.empty?
          query.string "group_id:" + group_id + "*"
        end
      end

    end

    s.results
  end

  def self.autocomplete(term, results_per_page = 10)
    q = term || "*"
    s = Tire.search(
          Settings.elasticsearch_product_index,
          load: true,
          search_type: 'dfs_query_and_fetch',
          size: results_per_page
    ) do |search|
        search.query { |query| query.string "name.partial:#{q}"}
        search.sort {by :followers, 'desc'}
      end
    s.results
  end
end
