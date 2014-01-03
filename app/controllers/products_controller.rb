class ProductsController < ApplicationController

  before_filter :authenticate                  , :only => [:edit, :edit_links, :edit_licenses, :update, :delete_link, :delete_license]
  before_filter :admin_user                    , :only => [:edit, :edit_links, :edit_licenses, :update, :delete_link, :delete_license]
  before_filter :check_redirects_package       , :only => [:show]
  before_filter :check_redirects_package_visual, :only => [:show_visual]
  before_filter :check_refer                   , :only => [:index]

  def index
    @user = User.new
    @ab = params['ab']
    if @ab.nil?
      # ab_array = ['a', 'b']
      @ab = 'b' # ab_array[Random.rand(2)]
    end
    @languages = supported_languages
    render :layout => 'application_lp'
  end

  def search
    @query   = do_parse_search_input( params[:q] )
    @groupid = params[:g]
    @lang    = get_lang_value( params[:lang] )
    if (@query.nil? || @query.empty?) && (@groupid.nil? || @groupid.empty?)
      flash.now[:error] = 'Please give us some input. Type in a value for name.'
    elsif @query.include?('%')
      flash.now[:error] = 'the character % is not allowed'
    else
      # start = Time.now
      languages = get_language_array(@lang)
      @products = ProductService.search( @query, @groupid, languages, params[:page])
      # save_search_log( @query, @products, start )
    end
    @languages = supported_languages
  end

  def show
    lang     = Product.decode_language( params[:lang] )
    prod_key = Product.decode_prod_key( params[:key]  )
    version  = params[:version]
    @product = fetch_product(lang, prod_key)
    if @product && !lang.eql?( @product.language )
      redirect_to package_version_path( @product.language_esc.downcase, @product.to_param, @product.version )
      return
    end
    if @product.nil?
      flash[:error] = 'The requested package is not available.'
      return
    end
    if version.nil? || (!attach_version(@product, version))
      params[:version] = @product.version
      redirect_to( {:action => 'show'}.merge(params) ) and return
    end
    if version
      @version   = @product.version_by_number(@product.version)
    end
    @current_version     = VersionService.newest_version( @product.versions )
    @versioncomment      = Versioncomment.new
    @versioncommentreply = Versioncommentreply.new
  end

  def show_visual
    lang = Product.decode_language( params[:lang] )
    key  = Product.decode_prod_key( params[:key]  )
    version  = params[:version]
    @product = Product.fetch_product lang, key
    if @product.nil?
      flash[:error] = 'The requested package is not available.'
      redirect_to '/'
      return
    end
    if version.nil? || (!attach_version(@product, version))
      redirect_to visual_dependencies_path( @product.language_esc.downcase, @product.to_param, @product.version )
      return
    end
    @version = @product.version_by_number( @product.version )
    render :layout => 'application_visual'
  end

  def badge
    language = Product.decode_language params[:lang]
    prod_key = Product.decode_prod_key params[:key]
    version  = Version.decode_version  params[:version]
    badge    = badge_for_product language, prod_key, version
    send_file "app/assets/images/badges/dep_#{badge}.png", :type => "image/png", :disposition => 'inline'
  end

  def references
    language   = Product.decode_language params[:lang]
    prod_key   = Product.decode_prod_key params[:key]
    page       = parse_page params[:page]
    @product   = Product.fetch_product language, prod_key
    response   = Dependency.references language, prod_key, page
    products   = Product.by_prod_keys language, response[:prod_keys]
    pre_amount = (page.to_i - 1) * 30
    pre        = Array.new pre_amount
    @products  = pre + products
    @products  = @products.paginate(:page => page, :per_page => 30)
    @products.total_entries = response[:count]
  end

  def edit
    lang     = Product.decode_language( params[:lang] )
    key      = Product.decode_prod_key params[:key]
    @product = Product.fetch_product lang, key
  end

  def edit_links
    lang     = Product.decode_language( params[:lang] )
    key      = Product.decode_prod_key params[:key]
    @product = Product.fetch_product lang, key
  end

  def edit_licenses
    lang     = Product.decode_language( params[:lang] )
    key      = Product.decode_prod_key params[:key]
    @product = Product.fetch_product lang, key
  end

  def update
    description     = params[:description_manual]
    license         = params[:license]
    license_link    = params[:licenseLink]
    license_version = params[:licenseVersion]
    twitter_name    = params[:twitter_name]
    link_url        = params[:link_url]
    link_name       = params[:link_name]
    lang            = Product.decode_language( params[:lang] )
    key             = Product.decode_prod_key params[:key]
    @product = Product.fetch_product lang, key
    if @product.nil? || !current_user.admin
      flash[:success] = "An error occured. Please try again later."
      redirect_to package_version_path(@product.language_esc, @product.to_param, @product.version)
      return
    end
    if description && !description.empty?
      @product.description_manual = description
      @product.save
      add_status_comment(@product, current_user, "description")
      flash[:success] = "Description updated."
    elsif license && !license.empty?
      license = License.new({:name => license, :url => license_link, :language => @product.language, :prod_key => @product.prod_key, :version => license_version})
      license.save
      add_status_comment(@product, current_user, "license", license.name)
      flash[:success] = "License updated."
    elsif twitter_name && !twitter_name.empty?
      @product.twitter_name = twitter_name
      @product.save
      add_status_comment(@product, current_user, "twitter")
      flash[:success] = "Twitter name updated."
    elsif link_url && !link_url.empty?
      versionlink = Versionlink.new
      versionlink.language = @product.language
      versionlink.prod_key = @product.prod_key
      versionlink.link = link_url
      versionlink.name = link_name
      versionlink.manual = true
      versionlink.save
      flash[:success] = "New link added."
    end
    redirect_to package_version_path(@product.language_esc, @product.to_param, @product.version)
  end

  def delete_link
    link_url = params[:link_url]
    lang     = Product.decode_language( params[:lang] )
    key      = Product.decode_prod_key params[:key]
    @product = Product.fetch_product lang, key
    versionlink = Versionlink.find_by( lang, key, link_url )
    if versionlink && versionlink.manual
      versionlink.remove
      flash[:success] = "Link removed."
    end
    redirect_to package_version_path(@product.language_esc, @product.to_param, @product.version)
  end

  def delete_license
    license_id = params[:license_id]
    lang     = Product.decode_language( params[:lang] )
    key      = Product.decode_prod_key params[:key]
    @product = Product.fetch_product lang, key
    license = License.find( license_id )
    if license
      license.remove
      flash[:success] = "License removed."
    end
    redirect_to package_version_path(@product.language_esc, @product.to_param, @product.version)
  end

  def follow
    lang_param       = params[:product_lang]
    @prod_key_param  = params[:product_key]
    product_key      = Product.decode_prod_key @prod_key_param
    language         = Product.decode_language lang_param
    follow           = ProductService.follow language, product_key, current_user
    @prod_lang_param = Product.language_escape language
    respond_to do |format|
      format.js
      format.json {render json: {success: follow}}
      format.html {
        unless follow
          flash.now[:error] = "An error occured. Please try again later and contact the VersionEye Team."
        end
        product = Product.fetch_product( language, product_key )
        redirect_to package_version_path( product.language_esc, product.to_param, product.version )
      }
    end
  end

  def unfollow
    src_hidden       = params[:src_hidden]
    lang_param       = params[:product_lang]
    @prod_key_param  = params[:product_key]
    language         = Product.decode_language lang_param
    product_key      = Product.decode_prod_key @prod_key_param
    unfollow         = ProductService.unfollow language, product_key, current_user
    @prod_lang_param = Product.language_escape language
    respond_to do |format|
      format.js
      format.json {render json: {success: unfollow}}
      format.html {
          unless unfollow
            flash.now[:error] = "An error occured. Please try again later."
          end
          if src_hidden.eql? "detail"
            product = Product.fetch_product(language, product_key)
            redirect_to package_version_path( product.language_esc, product.to_param, product.version )
          else
            redirect_to user_path( current_user )
          end
        }
    end
  end

  def autocomplete_product_name
    term = params[:term] || "nothing"
    term.gsub!(/\W/, "?") #replace all not-prinable chars with ?
    results = []
    products = EsProduct.autocomplete(term)
    products.each_with_index do |product, index|
      results << format_autocomplete(product)
      break if index > 9
    end
    render :json => results
  end

  private

    def parse_page page
      return 1 if page.to_s.empty?
      return 1 if page.to_i < 1
      page
    end

    def format_autocomplete(product)
      {
        value: "#{product[:name_downcase]}",
        name: product[:name],
        language: Product.encode_language(product[:language]),
        description: product.short_summary,
        prod_key: product[:prod_key],
        version: product[:version],
        followers: product[:followers],
        url: product.to_url_path
      }
    end

    def fetch_product( lang, prod_key )
      product = Product.fetch_product lang, prod_key
      if product.nil? && lang.eql?( Product::A_LANGUAGE_CLOJURE )
        product = Product.fetch_product Product::A_LANGUAGE_JAVA, prod_key
      end
      product
    end

    def add_status_comment(product, user, type, license = "")
      comment             = Versioncomment.new
      comment.user_id     = user.id
      comment.product_key = product.prod_key
      comment.prod_name   = product.name
      comment.language    = product.language
      comment.version     = product.version
      if type.eql?("description")
        comment.comment = "UPDATE: #{user.fullname} updated the description"
        comment.update_type = type
      elsif type.eql?("license")
        comment.comment = "UPDATE: #{user.fullname} updated the license to #{license}"
        comment.update_type = type
      elsif type.eql?("twitter")
        comment.comment = "UPDATE: #{user.fullname} updated the Twitter name to #{@product.twitter_name}"
        comment.update_type = type
      end
      comment.save
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end

    def supported_languages
      [Product::A_LANGUAGE_JAVA, Product::A_LANGUAGE_RUBY,
      Product::A_LANGUAGE_PYTHON, Product::A_LANGUAGE_PHP, Product::A_LANGUAGE_NODEJS,
      Product::A_LANGUAGE_CLOJURE, Product::A_LANGUAGE_R, Product::A_LANGUAGE_OBJECTIVEC]
    end

end
