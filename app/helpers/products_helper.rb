module ProductsHelper

  include ActionView::Helpers::DateHelper
  require 'semverly'

  def alternative_packages lang
    Product.where(:language => lang).desc(:used_by_count).limit(30)
  end

  def product_page_title( product )
    return product.short_summary if product && !product.short_summary.to_s.strip.empty?
    return 'Track your Open Source Libraries at VersionEye'
  end

  def product_version_path( product, version = nil )
    return '/0/0/0' if product.nil? || product.prod_key.nil?
    lang = product.language.gsub("\.", '')
    if version.nil?
      version = product.version_to_url_param
    end
    "/#{lang.downcase}/#{product.to_param}/#{version}"
  end

  def product_url(product)
    return '/0/0' if product.nil? || product.prod_key.nil?
    lang = product.language.gsub("\.", '')
    "/#{lang.downcase}/#{product.to_param}"
  end

  def product_url_for_projectdependency dependency
    return "" if dependency.nil? || dependency.prod_key.to_s.empty?
    return product_url(dependency) if dependency.is_a?(Product)

    language = Product.encode_language dependency.language
    prod_key = Product.encode_prod_key dependency.prod_key
    version  = Version.encode_version dependency.version_requested
    return "/#{language}/#{prod_key}/#{version}"
  end

  def url_for_dep dependency
    return "" if dependency.nil?
    language = dependency.language_escaped
    if dependency.prod_type.eql?(Project::A_TYPE_BOWER)
      product = Product.fetch_bower dependency.name
      language = product.language_esc if product
    end
    return "/#{language}/#{dependency.dep_prod_key_for_url}/#{dependency.version_for_url}"
  end

  def user_follows?( product, user )
    return false if user.products.nil? || user.products.empty?
    return true if user.product_ids.include?( product.id )
    false
  end

  def display_follow(product, user)
    return 'block' if user.products.nil? || user.products.empty?
    return 'none' if user.product_ids.include?( product.id )
    'block'
  end

  def display_unfollow(product, user)
    return 'none' if user.products.nil? || user.products.empty?
    return 'block' if user.product_ids.include?( product.id )
    'none'
  end

  def do_parse_search_input( query )
    if query.eql?('Follow your software libraries')
      query = 'json'
    end
    query = query.to_s.strip()
    query.downcase
  end

  def ref_color_for count
    return "red" if count.to_i < 1
    return "orange" if count.to_i < 11
    return "yellow" if count.to_i < 101
    return "green"
  end

  def get_lang_value( lang )
    lang = ',' if lang.nil? || lang.empty?
    lang
  end

  def get_language_array(lang)
    languages = Array.new
    special_languages = {'php' => 'PHP',
                         'javascript' => 'JavaScript',
                         'Javascript' => 'JavaScript',
                         'node.js' =>  'Node.JS',
                         'nodejs' => 'Node.JS',
                         'CSharp' => 'CSharp',
                         'Csharp' => 'CSharp',
                         'csharp' => 'CSharp'}

    langs = lang.split(",")
    langs.each do |language|
      unless language.strip.empty?
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

  def attach_version(product, version)
    return false if product.nil?

    version = product.version if version.to_s.empty?
    if version.to_s.empty?
      add_default_version product
      version = "0.0.0+NA"
    end

    version_obj = product.version_by_number( version )
    if version_obj.nil?
      version_obj = Version.new(:version => product.version, :created_at => DateTime.now)
    end
    product.version = version_obj.to_s
    update_release_infos( version_obj, product )
    true
  end

  def add_default_version product
    version = "0.0.0+NA"
    product.version = version
    product.add_version version
    product.save
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
    nil
  end

  def fetch_version( product )
    version = product.version_by_number product.version
    if version.nil?
      version = Version.new(:version => product.version, :created_at => DateTime.now)
    end
    parse_semver_2( version )
    version
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
    nil
  end

  def parse_semver_2 version
    version.semver_2 = version.to_s.match(/\A\d+\.\d+\.\d+-?.*/)
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end

  def update_release_infos( version_obj, product )
    return nil if version_obj.nil?
    today = DateTime.now.to_date
    if version_obj.released_at
      diff_release = today - version_obj.released_at.to_date
      product.released_days_ago = diff_release.to_i
      last_date = Date.today - product.released_days_ago
      product.released_ago_in_words = distance_of_time_in_words(Date.today, last_date)
      created_at = version_obj.created_at
      created_at = version_obj.released_at if created_at.nil?
      product.released_ago_text = "This artifact was released #{product.released_ago_in_words} ago on #{created_at.strftime("%b %d, %Y - %I:%m %p")}"
    else
      version_obj.created_at = DateTime.now if version_obj.created_at.nil?
      diff = today - version_obj.created_at.to_date
      product.released_days_ago = diff.to_i
      product.released_ago_in_words = distance_of_time_in_words(Date.today, version_obj.created_at)
      product.released_ago_text = "We don't have any information about the release date of this artifact, but we detected it #{product.released_ago_in_words} ago on #{version_obj.created_at.strftime("%b %d, %Y - %H:%M")}"
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

  def check_redirects_package
    check_redirects( "package" )
  end

  def check_redirects_package_visual
    check_redirects( "package_visual" )
  end

  def check_redirects( directory = "package" )
    key           = params[:key]
    version       = params[:version]
    version       = "" if version.nil?
    key_match_1   = key.match(/\~/)
    key_match_2   = key.match(/.+\-\-.+/)
    version_match = version.match(/\~/)
    return nil if key_match_1.nil? && key_match_2.nil? && version_match.nil?
    path  = "/#{directory}/"
    key_  = check_tilde key
    key__ = check_group_sep key_
    path  += "#{key__}"
    if version_match || !version.to_s.empty?
      version_ = check_tilde version
      path += "/#{version_}"
    end
    if !key_match_1.nil? || !key_match_2.nil? || !version_match.nil?
      redirect_to path
    end
  end

  def check_tilde key
    return key.gsub("\~", "\.") if key.match(/\~/)
    key
  end

  def check_group_sep key
    return key.gsub("--", ":") if key.match(/.+\-\-.+/)
    key
  end

  def ref_count product
    @products.respond_to?("total_entries") ? @products.total_entries : 0
  end

  def font_size_for_dep_table( product )
    if product.language.eql?( Product::A_LANGUAGE_JAVA )
      return '12'
    end
    '14'
  end

  def current_version( dependency )
    if dependency.known && dependency.product
      return dependency[:current_version]
    end
    if dependency.language.eql?(Product::A_LANGUAGE_PHP) && dependency.dep_prod_key.to_s.match(/\Aext-.*/i)
      return '*'
    end
    'UNKNOWN'
  end

  def dependency_name( dependency )
    if dependency.group_id && dependency.artifact_id
      return "#{dependency.group_id}:#{dependency.artifact_id}"
    end
    dep_name = dependency.name
    dep_name = dependency.dep_prod_key if dep_name.to_s.empty?
    dep_name
  end

  def maintainer?( product = nil )
    return false if current_user.nil?
    return false if current_user.maintainer.nil? || current_user.maintainer.empty?

    product = find_product if product.nil?
    return false if product.nil?

    @product = product

    return true  if current_user.admin == true
    return true if current_user.maintainer.include?("ALL")
    key = "#{product.language}\:\:#{product.prod_key}".downcase
    return true if current_user.maintainer.include?(key)

    return false
  end

  def fetch_projectdependency(product, project_id)
    Projectdependency.where(:language => product.language, :prod_key => product.prod_key, :project_id => project_id).first
  end

  def color_for_avg_release_time product
    art_bg = 'info'
    average_release_time = product[:average_release_time]
    if !average_release_time.nil? && average_release_time > 0
      art_bg = 'success' if average_release_time > 0 && average_release_time <= 31
      art_bg = 'info'  if average_release_time > 31 && average_release_time <= 62
      art_bg = 'warn'  if average_release_time > 62 && average_release_time <= 124
      art_bg = 'error' if average_release_time > 124
    else
      art_bg = "error"
    end
    art_bg
  end

  def color_for_released_ago product
    rel_bg = ''
    return rel_bg if product.nil? || product.released_days_ago.to_s.empty?

    days_ago = product.released_days_ago
    rel_bg = 'success' if days_ago < 30
    rel_bg = 'info'    if days_ago >= 30 && days_ago <= 180
    rel_bg = 'warn'    if days_ago > 180  && days_ago <= 365
    rel_bg = 'error'   if days_ago > 365
    rel_bg
  end

  def unread_notification_count
    Notification.by_user( current_user ).where(:read => false).count
  end

  private

    def find_product
      lang    = Product.decode_language params[:lang]
      key     = Product.decode_prod_key params[:key]
      Product.fetch_product lang, key
    end

end
