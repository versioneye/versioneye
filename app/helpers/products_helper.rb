module ProductsHelper

  def product_version_path(product)
    return "/package/0/version" if product.nil?
    return "/package/#{product.to_param}/version/#{product.version_to_url_param}"
  end

  def product_url(product)
    return "/package/0/" if product.nil?
    return "/package/#{product.to_param}"
  end

  def display_follow(product, user)
    return "none" if user.products.include? product
    return "block"
  end

  def display_unfollow(product, user)
    return "block" if user.products.include? product
    return "none"
  end

  def do_parse_search_input( query )
    query_empty = query.nil? || query.empty? || query.strip.empty? || query.eql?("Be up-to-date")
    query = "json" if query_empty
    query = query.strip()
    query = query.downcase
    return query
  end

  def get_lang_value( lang )
    lang = "," if lang.nil? || lang.empty?
    lang
  end

  def get_language_array(lang)
    languages = Array.new
    special_languages = {"php" => "PHP",
                          "node.js" =>  "Node.JS",
                          "nodejs" => "Node.JS"}

    langs = lang.split(",")
    langs.each do |language|
      if !language.strip.empty?
        language = language.downcase
        if special_languages.has_key? language
          languages.push(special_languages[language])
        else
          languages.push(language.capitalize)
        end
      end
    end
    languages
  end

  def attach_version(product, version_from_url)
    return nil if product.nil?
    version = Version.decode_version( version_from_url )
    if version.nil? || version.empty?
      version = product.version
    end
    versionObj = product.version_by_number( version )
    if versionObj
      product.version = versionObj.version
      product.version_link = versionObj.link
      update_release_infos( versionObj, product )
    end
  end

  def update_release_infos( versionObj, product )
    if versionObj.created_at
      today = DateTime.now.to_date
      diff = today - versionObj.created_at.to_date
      product.last_crawle_date = diff.to_i
      if versionObj.released_at
        diff_release = today - versionObj.released_at.to_date
        product.released_days_ago = diff_release.to_i
      end
    end
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

  def check_redirects
    key           = params[:key]
    version       = params[:version]
    version       = "" if version.nil?
    key_match     = key.match(/\~/)
    version_match = version.match(/\~/)
    return nil if key_match.nil? && version_match.nil?
    path = "/package/"
    if key_match
      key_ = key.gsub("\~", "\.")
      path += "#{key_}"
    else
      path += "#{key}"
    end
    if version_match
      version_ = version.gsub("\~", "\.")
      path += "/version/#{version_}"
    end
    if !key_match.nil? || !version_match.nil?
      redirect_to path
      return
    end
  end

end
