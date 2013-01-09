class ProductElastic

  def self.create_index_with_mappings
    Tire.index Settings.elasticsearch_product_index do
      create :mappings => {
        :product => {
          :properties => {
            :_id                => { :type => 'string', :analyzer => 'keyword', :include_in_all => false },
            :name => { :type => 'multi_field', :fields => {
                :name => {:type => 'string', :analyzer => 'snowball', :boost => 100}, 
                :untouched => {:type => 'string', :analyzer => 'keyword' }
              } },
            :description        => { :type => 'string', :analyzer => 'snowball' },
            :description_manual => { :type => 'string', :analyzer => 'snowball' },
            :language           => { :type => 'string', :analyzer => 'keyword' }
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
    # Tire.index( Settings.elasticsearch_product_index ).import Product.all
    Product.all.each do |product|  
      ProductElastic.index product
    end
    self.refresh
  end

  def self.index( product )
    p "index #{product.name}"
    Tire.index Settings.elasticsearch_product_index do
      store product.to_indexed_json 
      product.update_attribute(:reindex, false)
    end
  rescue => e 
    p "ERROR in index(product) Message:   #{e.message}"
    p "ERROR in index(product) backtrace: #{e.backtrace}"
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
      ProductElastic.index product
    end
    self.refresh
    Product.where(reindex: nil).each do |product|
      ProductElastic.index product
    end
    self.refresh
  end

  # # langs need to be an Array ! 
  # # page_count has to start by 1. Not by 0! 
  # # 
  def self.search(q, group_id = nil, langs = Array.new, page_count = 1)
    if (q.nil? || q.empty?) && (group_id.nil? || group_id.empty?)
      raise ArgumentError, "query and group_id are both empty! This is not allowed"
    end

    page_count = 1 if page_count.nil? || page_count.to_i < 1 
    results_per_page = 30
    from = results_per_page * (page_count.to_i - 1)
    
    group_id = "" if !group_id
    q = "*" if !q || q.empty?

    s = Tire.search( Settings.elasticsearch_product_index, 
                      load: true, 
                      from: from,
                      per_page: results_per_page, 
                      size: results_per_page) do |search|

      search.sort { by [{:_score => 'desc'}] }
      # search.sort { by [{'name.untouched' => 'asc'}] }
      
      if langs and !langs.empty?
        # langs_dwoncase = Product.downcase_array langs
        search.filter :terms, :language => langs
      end
      
      search.query do |query|  
        if q != '*' and !group_id.empty?
          # when user search by name and group_id
          query.boolean do 
            must {string 'name:' + q}
            must {string 'group_id:' + group_id + "*"}                                                     
          end 
        elsif q != '*' and group_id.empty?          
          query.string "name:" + q
        elsif q == '*' and !group_id.empty?
          query.string "group_id:" + group_id + "*"  
        end 
      end

    end

    s.results
  end

  def self.search_exact(name)
    s = Tire.search( Settings.elasticsearch_product_index, load: true) do |search|
      response = search.query do |query|
        query.boolean do
          must {string name, default_operator: "AND" }           
        end 
      end
      #filter result by hand
      result = []
      response.results.each do |item|        
        if item.name.eql? name then
            result << item
        end
      end
      return result 
    end
  end 

end