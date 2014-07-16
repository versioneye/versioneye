class Es

  def self.search q
    s = Tire.search(Settings.instance.elasticsearch_product_index, load: true, search_type: 'dfs_query_and_fetch', size: 30) do |search|
      search.query do |query|
        query.string "name:#{q}"
      end
      # search.filter :terms, :language => ["Ruby"]
      search.facet 'lang-glob', :global => true do
        terms :language
      end
      search.facet 'lang-loc' do
        terms :language
      end
      search.sort {by :followers, 'desc'}
    end
    s
  end

end
