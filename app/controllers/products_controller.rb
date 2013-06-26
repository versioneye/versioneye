class ProductsController < ApplicationController

  before_filter :authenticate                  , :only => [:edit, :update]
  before_filter :check_redirects_package       , :only => [:show]
  before_filter :check_redirects_package_visual, :only => [:show_visual]
  #before_filter :force_http

  @@languages = [Product::A_LANGUAGE_JAVA, Product::A_LANGUAGE_RUBY,
    Product::A_LANGUAGE_PYTHON, Product::A_LANGUAGE_PHP, Product::A_LANGUAGE_NODEJS,
    Product::A_LANGUAGE_JAVASCRIPT, Product::A_LANGUAGE_CLOJURE, Product::A_LANGUAGE_R]

  def index
    @lang = cookies[:veye_lang]
    if @lang.nil?
      @lang = ""
      cookies[:veye_lang] = ""
    end
    @languages = @@languages
    render :layout => 'application_lp'
  end

  def search
    @query   = do_parse_search_input( params[:q] )
    @groupid = params[:g]
    @lang    = get_lang_value( params[:lang] )
    commit   = params[:commit]
    if ( (@query.nil? || @query.empty?) && (@groupid.nil? || @groupid.empty?) )
      flash.now[:error] = "Please give us some input. Type in a value for name."
    elsif @query.include?("%")
      flash.now[:error] = "the character % is not allowed"
    else
      start = Time.now
      languages = get_language_array(@lang)
      @products = ProductService.search( @query, @groupid, languages, params[:page])
      # save_search_log( @query, @products, start )
    end
    @languages = @@languages
  end

  def show
    lang     = Product.decode_language( params[:lang] )
    prod_key = Product.decode_prod_key( params[:key]  )
    version  = params[:version]
    @product = Product.fetch_product lang, prod_key
    if @product.nil?
      flash[:error] = "The requested package is not available."
      return
    end
    if version.nil?
      redirect_to package_version_path(@product.language.downcase, @product.to_param, @product.version)
      return
    end
    attach_version( @product, version )
    if @product.version
      @version   = @product.version_by_number @product.version
    end
    @versioncomment      = Versioncomment.new
    @versioncommentreply = Versioncommentreply.new
  end

  def show_visual_old
    key      = params[:key]
    version  = params[:version]
    prod_key = key.gsub(":", "/").gsub("~", ".").gsub("--", "/")
    product  = Product.find_by_key( prod_key )
    new_path = "/"
    if product
      new_path += "#{product.language.downcase}/#{product.to_param}"
      if version
        new_path += "/#{version}"
      end
      new_path += "/visual_dependencies"
    end
    redirect_to new_path
  end

  def show_visual
    lang = Product.decode_language( params[:lang] )
    key  = Product.decode_prod_key( params[:key]  )
    @product = Product.fetch_product lang, key
    if @product.nil?
      flash[:error] = "The requested package is not available."
      redirect_to package_version_path(@product.language.downcase, @product.to_param, @product.version)
      return
    end
    attach_version( @product, params[:version] )
    @version = @product.version_by_number( @product.version )
    render :layout => 'application_visual'
  end

  def badge
    lang     = Product.decode_language( params[:lang] )
    prod_key = Product.decode_prod_key params[:key]
    badge    = "unknown"
    @product = Product.fetch_product lang, prod_key
    unless @product.nil?
      version = Version.decode_version params[:version]
      if !version.nil? && !version.empty?
        @product.version = version
      end
      if DependencyService.dependencies_outdated?( @product.dependencies )
        badge = "out-of-date"
      else
        badge = "up-to-date"
      end
    end
    send_file "app/assets/images/badges/dep_#{badge}.png", :type => "images/png", :disposition => 'inline'
  end

  def edit
    lang     = Product.decode_language( params[:lang] )
    key      = Product.decode_prod_key params[:key]
    @product = Product.fetch_product lang, key
  end

  def update
    description  = params[:description_manual]
    license      = params[:license]
    licenseLink  = params[:licenseLink]
    twitter_name = params[:twitter_name]
    link_url     = params[:link_url]
    link_name    = params[:link_name]
    lang         = Product.decode_language( params[:lang] )
    key          = Product.decode_prod_key params[:key]
    @product = Product.fetch_product lang, key
    if @product.nil? || !current_user.admin
      flash[:success] = "An error occured. Please try again later."
      redirect_to package_version_path(@product.language.downcase, @product.to_param, @product.version)
      return
    end
    if description && !description.empty?
      @product.description_manual = description
      @product.save
      add_status_comment(@product, current_user, "description")
      flash[:success] = "Description updated."
    elsif license && !license.empty?
      @product.license_manual = license
      @product.licenseLink_manual = licenseLink
      @product.save
      add_status_comment(@product, current_user, "license")
      flash[:success] = "License updated."
    elsif twitter_name && !twitter_name.empty?
      @product.twitter_name = twitter_name
      @product.save
      add_status_comment(@product, current_user, "twitter")
      flash[:success] = "Twitter name updated."
    elsif link_url && !link_url.empty?
      versionlink = Versionlink.new
      versionlink.prod_key = @product.prod_key
      versionlink.link = link_url
      versionlink.name = link_name
      versionlink.manual = true
      versionlink.save
      flash[:success] = "New link added."
    end
    redirect_to package_version_path(@product.language.downcase, @product.to_param, @product.version)
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
    redirect_to package_version_path(@product.language.downcase, @product.to_param, @product.version)
  end

  def follow
    @prod_lang_param = params[:product_lang]
    @prod_key_param  = params[:product_key]
    product_key      = Product.decode_prod_key @prod_key_param
    language         = Product.decode_language @prod_lang_param
    follow           = ProductService.follow language, product_key, current_user
    respond_to do |format|
      format.js
      format.html {
        if !follow
          flash.now[:error] = "An error occured. Please try again later and contact the VersionEye Team."
        end
        product = Product.fetch_product( language, product_key )
        redirect_to package_version_path( product.language.downcase, product.to_param, product.version )
      }
    end
  end

  def unfollow
    src_hidden       = params[:src_hidden]
    @prod_lang_param = Product.decode_language( params[:product_lang] )
    @prod_key_param  = params[:product_key]
    language         = Product.decode_language @prod_lang_param
    product_key      = Product.decode_prod_key @prod_key_param
    unfollow         = ProductService.unfollow language, product_key, current_user
    respond_to do |format|
      format.js
      format.html {
          if !unfollow
            flash.now[:error] = "An error occured. Please try again later."
          end
          if src_hidden.eql? "detail"
            product = Product.fetch_product(language, product_key)
            redirect_to package_version_path( product.language.downcase, product.to_param, product.version )
          else
            redirect_to user_path( current_user )
          end
        }
    end
  end

  def autocomplete_product_name
    lang      = get_lang_value( params )
    languages = lang.split(",")
    @products = Product.find_by_name(params[:term], languages, 10).paginate(:page => 1)
    respond_to do |format|
      format.json { render :json => @products.as_json(:only => [:name]) }
    end
  end

  private

    def add_status_comment(product, user, type)
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
        comment.comment = "UPDATE: #{user.fullname} updated the license to #{@product.license_manual}"
        comment.update_type = type
      elsif type.eql?("twitter")
        comment.comment = "UPDATE: #{user.fullname} updated the Twitter name to #{@product.twitter_name}"
        comment.update_type = type
      end
      comment.save
    end

end
