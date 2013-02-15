require 'htmlentities'

module VersionEye
  module ProductHelpers
    def parse_query(query)
        query = query.to_s
        query = query.strip().downcase 
        query.gsub!(/\%/, "")
        query
    end

    def get_language_param(lang)
      lang = lang.to_s
      lang = "," if lang.empty?
      lang
    end

    def get_language_array(lang)
      languages = []
      special_languages = {
        "php" => "PHP",
        "node.js" =>  "Node.JS",
        "nodejs" => "Node.JS"
      }

      langs = lang.split(",")
      langs.each do |language|
        language.to_s.strip.downcase!
        if language.length > 0
          if special_languages.has_key?(language)
            languages << special_languages[language]
          else
            languages << language.capitalize!
          end
        end
        
        languages
      end
    end

    # TODO move to Product.rb -> decode_product_key
    def parse_product_key(prod_key)
      parsed_key = prod_key.to_s.gsub("--", "/").gsub("~", ".")
      HTMLEntities.new.decode parsed_key
    end

    def fetch_product(prod_key)
      prod_key = parse_product_key(prod_key)
      @current_product = Product.find_by_key prod_key
      if @current_product.nil?
        error! "Wrong product key: `#{params[:prod_key]}` dont exists.", 404
      end
      @current_product
    end
    
    def save_search_log(query, products, start)
      stop = Time.now
      wait = (stop - start) * 1000.0
      searchlog = Searchlog.new
      searchlog.search = query
      searchlog.wait = wait
      if products.nil? || products.total_entries == 0
        searchlog.results = 0  
      else
        searchlog.results = products.total_entries
      end
      searchlog.save
    end

  end
end
