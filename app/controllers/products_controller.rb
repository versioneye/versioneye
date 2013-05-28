class ProductsController < ApplicationController

  before_filter :authenticate, :only   => [:edit, :update]
  #before_filter :force_http

  @@languages = [Product::A_LANGUAGE_JAVA, Product::A_LANGUAGE_RUBY,
    Product::A_LANGUAGE_PYTHON, Product::A_LANGUAGE_NODEJS, Product::A_LANGUAGE_PHP,
    Product::A_LANGUAGE_R, Product::A_LANGUAGE_JAVASCRIPT, Product::A_LANGUAGE_CLOJURE]

  def index
    @page = "LandingPage"
    @lang = cookies[:veye_lang]
    if @lang.nil?
      @lang = ""
      cookies[:veye_lang] = ""
    end
    @languages = @@languages
    render :layout => 'application_lp'
  end

  def search
    @query = do_parse_search_input( params[:q] )
    @groupid = params[:g]
    @lang = get_lang_value( params[:lang] )
    @page = "search"
    commit = params[:commit]

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

  def autocomplete_product_name
    lang = get_lang_value( params )
    languages = lang.split(",")
    @products = Product.find_by_name(params[:term], languages, 10).paginate(:page => 1)
    respond_to do |format|
      format.json { render :json => @products.as_json(:only => [:name]) }
    end
  end

  def show
    key = Product.decode_prod_key params[:key]
    @product = Product.find_by_key( key )
    if @product.nil?
      @product = Product.find_by_key_case_insensitiv( key )
    end
    if @product.nil?
      flash[:error] = "The requested package is not available."
      return
    end

    attach_version( @product, params[:version] )
    if @product.version
      @version = @product.version_by_number @product.version
      @downloads = @version.versionarchive
    end
    @main_dependencies = @product.dependencies(nil)

    @versioncomment = Versioncomment.new
    @versioncommentreply = Versioncommentreply.new
    @page = "product_show"
  end

  def show_visual
    key = Product.decode_prod_key( params[:key] )
    @product = Product.find_by_key( key )
    if @product.nil?
      flash[:error] = "The requested package is not available."
      redirect_to products_path(@product)
      return
    end
    attach_version( @product, params[:version] )
    @version = @product.version_by_number( @product.version )
    @main_dependencies = @product.dependencies(nil)
    render :layout => 'application_visual'
  end

  def badge
    prod_key = Product.decode_prod_key params[:key]
    path = "app/assets/images/badges"
    badge = "unknown"
    @product = Product.find_by_key(prod_key)
    unless @product.nil?
      version = Version.decode_version params[:version]
      if !version.nil? && !version.empty?
        @product.version = version
      end
      if @product.dependencies_outdated?()
        badge = "out-of-date"
      else
        badge = "up-to-date"
      end
    end
    send_file "#{path}/dep_#{badge}.png", :type => "images/png", :disposition => 'inline'
  end

  def edit
    key = Product.decode_prod_key params[:key]
    @product = Product.find_by_key( key )
  end

  def delete_link
    link_url = params[:link_url]
    key = Product.decode_prod_key params[:key]
    @product = Product.find_by_key( key )
    versionlink = Versionlink.find_by(key, link_url)
    if versionlink && versionlink.manual
      versionlink.remove
      flash[:success] = "Link removed."
    end
    redirect_to products_path(@product)
  end

  def update
    description = params[:description_manual]
    license = params[:license]
    licenseLink = params[:licenseLink]
    twitter_name = params[:twitter_name]
    link_url = params[:link_url]
    link_name = params[:link_name]
    key = Product.decode_prod_key params[:key]
    @product = Product.find_by_key( key )
    if @product.nil? || !current_user.admin
      flash[:success] = "An error occured. Please try again later."
      redirect_to products_path(@product)
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
    redirect_to products_path(@product)
  end

  def follow
    @prod_key_param = params[:product_key]
    product_key = Product.decode_prod_key @prod_key_param
    follow = ProductService.follow product_key, current_user
    respond_to do |format|
      format.js
      format.html {
        if !follow
          flash.now[:error] = "An error occured. Please try again later and contact the VersionEye Team."
        end
        redirect_to products_path(@prod_key_param)
      }
    end
  end

  def unfollow
    src_hidden = params[:src_hidden]
    @prod_key_param = params[:product_key]
    product_key = Product.decode_prod_key @prod_key_param
    unfollow = ProductService.unfollow product_key, current_user
    respond_to do |format|
      format.js
      format.html {
          if !unfollow
            flash.now[:error] = "An error occured. Please try again later."
          end
          if src_hidden.eql? "detail"
            redirect_to products_path(@prod_key_param)
          else
            redirect_to user_path(current_user)
          end
        }
    end
  end

  private

    def add_status_comment(product, user, type)
      comment = Versioncomment.new
      comment.user_id = user.id
      comment.product_key = product.prod_key
      comment.prod_name = product.name
      comment.language = product.language
      comment.version = product.version
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
