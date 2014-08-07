module ProductsHelper

  include ActionView::Helpers::DateHelper
  require 'semverly'

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

  def url_for_dep dependency
    return "" if dependency.nil?
    language = dependency.language_escaped
    if dependency.prod_type.eql?(Project::A_TYPE_BOWER)
      product = Product.fetch_bower dependency.dep_prod_key
      language = product.language_escaped
    end
    return "/#{language}/#{dependency.dep_prod_key_for_url}/#{dependency.version_for_url}"
  end

  def user_follows?(product, user)
    return false if user.products.nil? || user.products.empty?
    return true if user.products.include?(product)
    false
  end

  def display_follow(product, user)
    return 'block' if user.products.nil? || user.products.empty?
    return 'none' if user.products.include? product
    'block'
  end

  def display_unfollow(product, user)
    return 'none' if user.products.nil? || user.products.empty?
    return 'block' if user.products.include? product
    'none'
  end

  def do_parse_search_input( query )
    query_empty = query.nil? || query.empty? || query.strip.empty? || query.eql?('search for a software library')
    query = 'json' if query_empty
    query = query.strip()
    query.downcase
  end

  def badge_for_product( language, prod_key, version )
    key   = "#{language}_#{prod_key}_#{version}"
    badge = Rails.cache.read key
    return badge if badge

    product = Product.fetch_product language, prod_key
    return 'unknown' if product.nil?

    product.version = version if version
    dependencies    = product.dependencies

    if dependencies.nil? || dependencies.empty?
      badge = 'none'
      Rails.cache.write( key, badge, timeToLive: 2.hour )
      return badge
    end

    outdated = DependencyService.dependencies_outdated?( dependencies, true )
    badge = 'out-of-date' if outdated == true
    badge = 'up-to-date'  if outdated == false
    Rails.cache.write( key, badge, timeToLive: 24.hour )
    badge
  end

  def ref_badge_for_product( language, prod_key )
    key   = "ref_badge_#{language}_#{prod_key}"
    badge = Rails.cache.read key
    return badge if badge

    reference = ReferenceService.find_by language, prod_key
    return '0' if reference.nil?

    Rails.cache.write( key, reference.ref_count, timeToLive: 24.hour )
    return "#{reference.ref_count}"
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
                         'nodejs' => 'Node.JS'}

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

    version = product.version if version.nil? || version.empty?
    version_obj = product.version_by_number( version )
    if version_obj.nil?
      version_obj = Version.new(:version => product.version, :created_at => DateTime.now)
    end
    product.version = version_obj.to_s
    update_release_infos( version_obj, product )
    true
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
    version.semver_2 = SemVer.parse( version.to_s )
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
      product.released_ago_text = "This artifact was released #{product.released_ago_in_words} ago on #{version_obj.created_at.strftime("%b %d, %Y - %I:%m %p")}"
    else
      version_obj.created_at = DateTime.now if version_obj.created_at.nil?
      diff = today - version_obj.created_at.to_date
      product.released_days_ago = diff.to_i
      product.released_ago_in_words = distance_of_time_in_words(Date.today, version_obj.created_at)
      product.released_ago_text = "We don't have any information about the release date of this artifact, but we detected it #{product.released_ago_in_words} ago on #{version_obj.created_at.strftime("%b %d, %Y - %I:%m %p")}"
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
      # return dependency.product.version
    end
    'UNKNOWN'
  end

  def dependency_name( dependency )
    if dependency.group_id && dependency.artifact_id
      return "#{dependency.group_id}:#{dependency.artifact_id}"
    end
    dependency.name
  end

end
