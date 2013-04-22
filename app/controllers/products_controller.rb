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
    commit = params[:commit]

    if ( (@query.nil? || @query.empty?) && (@groupid.nil? || @groupid.empty?) )
      flash.now[:error] = "Please give us some input. Type in a value for name."
    elsif @query.include?("%")
      flash.now[:error] = "the character % is not allowed"
    else
      start = Time.now
      languages = get_language_array(@lang)
      @products = ProductService.search( @query, @groupid, languages, params[:page])
      if @products && @products.count > 0 && signed_in?
        @my_product_ids = current_user.fetch_my_product_ids 
      end
      save_search_log( @query, @products, start )
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
    
    @following = is_following?(current_user, @product)

    attach_version( @product, params[:version] )
    # @comments = @product.comments
    @version = @product.version_by_number @product.version
    @downloads = @version.versionarchive
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
    send_file "#{path}/version_#{badge}.png", :type => "images/png", :disposition => 'inline'
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
    respond = ProductService.create_follower product_key, current_user
    respond_to do |format|
      format.js 
      format.html { 
          if respond.eql?("error")
            flash.now[:error] = "An error occured. Please try again later."
          end      
          redirect_to products_path(@prod_key_param)
        }
    end
  end
  
  def unfollow
    src_hidden = params[:src_hidden]
    @prod_key_param = params[:product_key]
    product_key = Product.decode_prod_key @prod_key_param
    respond = ProductService.destroy_follower product_key, current_user
    respond_to do |format|
      format.js 
      format.html { 
          if respond.eql?("error")
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

  def recursive_dependencies
    key = Product.decode_prod_key params[:key]
    version = Version.decode_version params[:version]
    scope = params[:scope]
    product = Product.find_by_key( key )
    if version && !version.empty?
      product.version = version  
    end
    
    respond_to do |format|
      format.json { 
        
        circle = CircleElement.fetch_circle(key, version, scope)
        if circle && !circle.empty?
          resp = generate_json_for_circle_from_array( circle )
        else 
          circle = product.dependency_circle( scope )
          CircleElement.store_circle( circle, key, version, scope )
          resp = generate_json_for_circle_from_hash( circle )
        end

        render :json => "[#{resp}]"
      }
    end
  end

  def image_path
    image_key = params[:key]
    image_version = params[:version]
    scope = params[:scope]
    url = S3.infographic_url_for("#{image_key}:#{image_version}:#{scope}.png")  
    respond_to do |format|
      format.json { 
        if url_exist?(url)
          render :json => "#{url}"
        else
          render :json => "nil"
        end
      }
    end
  end

  def upload_image
    image_bin = params[:image]
    image_key = params[:key]
    image_version = params[:version]
    scope = params[:scope]
    filename = "#{image_key}:#{image_version}:#{scope}.png"
    image_bin.gsub!(/data:image\/png;base64,/, "")
    AWS::S3::S3Object.store(
      filename, 
      Base64.decode64(image_bin), 
      Settings.s3_infographics_bucket, 
      :access => "public-read")
    url = S3.infographic_url_for(filename)
    respond_to do |format|
      format.json { 
        render :json => "#{url}"
      }
    end
  end
  
  private

    def url_exist?(url_path)
      url = URI.parse(url_path)
      req = Net::HTTP.new(url.host, url.port)
      res = req.request_head(url.path)
      if res.code == "200"
        return true
      else
        return false
      end
    end

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

    def is_following?(user, product)
      if !user || !product
        return false
      end
      follower = Follower.find_by_user_id_and_product(user.id, product._id.to_s)
      if follower
        update_notification_status(follower)
        return true
      else 
        return false
      end
    end

    def update_notification_status(follower)
      if follower && follower.notification == true
        follower.notification = false
        follower.save
      end
    end

end
