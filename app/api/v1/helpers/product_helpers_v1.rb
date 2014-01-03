require 'htmlentities'


module ProductHelpersV1
  @@special_languages = {
    'pip' => 'Python',
    'npm' => 'Node.JS',
    'php' => 'PHP',
    'node.js' =>  'Node.JS',
    'nodejs' => 'Node.JS'
  }

  def parse_query(query)
      query = query.to_s
      query = query.strip().downcase
      query.gsub!(/\%/, "")
      query
  end

  def get_language_param(lang)
    lang = lang.to_s
    lang = ',' if lang.empty?
    lang
  end

  def get_language_array(lang)
    languages = []

    langs = lang.split(',')
    langs.each do |language|
      language.to_s.strip.downcase!
      if language.length > 0
        if @@special_languages.has_key?(language)
          languages << @@special_languages[language]
        else
          languages << language.capitalize!
        end
      end

      languages
    end
  end

  def parse_language(lang)
    parsed_lang = lang.downcase

    if @@special_languages.has_key?(parsed_lang)
      parsed_lang = @@special_languages[parsed_lang]
    else
      parsed_lang = parsed_lang.capitalize
    end

    if parsed_lang.to_s.empty?
      error! "Language `#{lang}`is not correct."
    end

    parsed_lang
  end

  def parse_product_key(prod_key)
    parsed_key = prod_key.to_s.gsub('--', '/')
    parsed_key = parsed_key.gsub('~', '.')
    HTMLEntities.new.decode parsed_key
  end

  def fetch_product( encoded_prod_key )
    if encoded_prod_key.match(/\-\-/).nil?
      key = encoded_prod_key.gsub('~', '.').gsub(':', '/')
      product = Product.find_by_key( key )
      if product
        return product
      else
        error! "Wrong product key: `#{params[:prod_key]}` don't exists.", 404
        return
      end
    end

    lang, prod_key = encoded_prod_key.split("--", 2)
    lang = parse_language( lang )
    prod_key = parse_product_key(prod_key)

    p "#-- fetch_product: #{lang} #{prod_key}"
    current_product = Product.fetch_product( lang, prod_key )
    if current_product.nil?
      error! "Wrong product key: `#{params[:prod_key]}` don't exists.", 404
    end
    current_product
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
