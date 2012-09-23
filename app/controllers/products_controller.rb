class ProductsController < ApplicationController

  before_filter :authenticate, :only   => [:edit, :update]
  #before_filter :force_http

  @@languages = ["Java", "Ruby", "Python", "Node.JS", "PHP", "R", "JavaScript", "Clojure"]

  def index
    @page = "LandingPage"
    @lang = cookies[:veye_lang]
    if @lang.nil?
      @lang = ""
      cookies[:veye_lang] = ""
    end
    @languages = @@languages # Product.get_unique_languages
    render :layout => 'application_lp'
  end
  
  def search
    @query = params[:q]
    @groupid = params[:g]
    @description = params[:d]
    @lang = get_lang_value( params, cookies )
    commit = params[:commit]
    
    hash = do_parse_search_input(@query, @description, @groupid)
    @query = hash['query'] if !hash['query'].nil?
    @groupid = hash['group'] if !hash['group'].nil?
    @description = hash['description'] if !hash['description'].nil?

    if ( (@query.nil? || @query.empty?) && (@description.nil? || @description.empty?) && (@groupid.nil? || @groupid.empty?) )
      flash.now[:error] = "Please give us some input. Type in a value for name or description."
    elsif @query.length == 1
      flash.now[:error] = "Search term is to short. Please type in at least 2 characters."
    elsif @query.include?("%")
      flash.now[:error] = "the character % is not allowed"
    else
      languages = get_language_array(@lang)
      #@products = Product.search( @query, @description, @groupid, languages, params[:page])
      @products = Product.find_by(@query, @description, @groupid, languages, 300).paginate(:page => params[:page])
      if @products.nil? || @products.count == 0
        flash.now[:notice] = "Sorry. No Results found."
      elsif signed_in?
        @my_product_ids = current_user.fetch_my_product_ids 
      end
      save_search_log(@query, @products)
    end    
    respond_to do |format|
      format.html { 
        @languages = @@languages
      }
      format.json { render :json => @products.to_json(:only => [:name, :version, :prod_key, :group_id, :artifact_id, :language] ) }
    end
  end

  def autocomplete_product_name
    lang = get_lang_value( params, cookies )
    languages = lang.split(",")
    @products = Product.find_by_name(params[:term], languages, 10).paginate(:page => 1)
    respond_to do |format|
      format.json { render :json => @products.as_json(:only => [:name]) }
    end
  end
  
  def show
    mobile = params[:mobile]
    key = url_param_to_origin params[:key]
    @product = Product.find_by_key( key )
    if @product.nil? 
      @product = Product.find_by_key_case_insensitiv( key )  
    end
    if @product.nil? 
      flash[:error] = "The requested package is not available."
      redirect_to "/"
      return 
    end
    
    @following = is_following?(current_user, @product)
    
    attach_version( @product, params[:version] )
    @comments = Versioncomment.find_by_prod_key_and_version(@product.prod_key, @product.version)
    @version = @product.get_version(@product.version)
    @downloads = @version.versionarchive
    @productlook = Productlook.find_by_key(key)
    @main_dependencies = @product.dependencies(nil)

    format = params[:format]
    if format && !format.eql?("html") && !format.eql?("json")
      redirect_to "/package/#{@product.to_param}/version/#{@version.to_url_param}"
      return 
    end

    respond_to do |format|
      format.html { 
        if !mobile.nil? && mobile.eql?('true')
          render "show_mobile", :layout => "application_mobile"
        else
          @users = Array.new
          user_ids = Follower.find_followers_for_product( @product.id )
          @users = User.find_by_ids(user_ids)
          @versioncomment = Versioncomment.new 
          @versioncommentreply = Versioncommentreply.new
        end          
        }
      format.json { 
        render :json => @product.to_json(:only => [:name, :version, :prod_key, :group_id, :artifact_id, :language, :prod_type, :description, :link, :license ] )
      }
    end
  end

  def show_visual
    key = url_param_to_origin params[:key]
    @product = Product.find_by_key( key )
    if @product.nil? 
      flash[:error] = "The requested package is not available."
      redirect_to products_path
      return 
    end
    attach_version( @product, params[:version] )
    @version = @product.get_version(@product.version)
    @main_dependencies = @product.dependencies(nil)
    render :layout => 'application_visual'
  end

  def edit
    key = url_param_to_origin params[:key]
    @product = Product.find_by_key( key )
  end

  def delete_link
    link_url = params[:link_url]
    key = url_param_to_origin params[:key]
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
    key = url_param_to_origin params[:key]
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
    product_key = url_param_to_origin params[:product_key]
    @product = fetch_product product_key
    @product.followers = @product.followers + 1
    @product.save
    respond = create_follower @product, current_user
    respond_to do |format|
      format.js 
      format.html { 
          redirect_to product_version_path(@product)
        }
      format.json { render :json => "[#{respond}]" }
    end
  end
  
  def unfollow
    src_hidden = params[:src_hidden]
    product_key = url_param_to_origin params[:product_key]    
    @product = fetch_product product_key
    @product.followers = @product.followers - 1
    @product.save
    respond = destroy_follower @product, current_user
    respond_to do |format|
      format.js 
      format.json { render :json => "[#{respond}]" }
      format.html { 
          if src_hidden.eql? "detail"
            redirect_to product_version_path(@product)
          else
            redirect_to user_path(current_user)
          end
        }
    end
  end

  def recursive_dependencies
    key = url_param_to_origin params[:key]
    version = url_param_to_origin params[:version]
    scope = params[:scope]
    product = Product.find_by_key( key )
    if !version.nil? && !version.empty?
      product.version = version  
    end
    @circle = product.dependency_circle(scope)
    respond_to do |format|
      format.json { 
        resp = generate_json_for_circle(@circle)
        render :json => "[#{resp}]"
      }
    end
  end

  def image_path
    image_key = params[:key]
    image_version = params[:version]
    scope = params[:scope]
    url = Product.get_infographic_url_from_s3("#{image_key}:#{image_version}:#{scope}.png")  
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
    url = Product.get_infographic_url_from_s3(filename)
    respond_to do |format|
      format.json { 
        render :json => "#{url}"
      }
    end
  end
  
  private

    def get_language_array(lang)
      langs = lang.split(",")
      p "langs: #{langs}"
      languages = Array.new 
      langs.each do |language|
        languages.push(language) if !language.strip.empty?
      end
      p "languages: #{languages}"
      languages
    end

    def get_lang_value( params, cookies )
      lang = params[:lang]
      if lang.nil? || lang.empty?
        lang = cookies[:veye_lang]
      else 
        cookies[:veye_lang] = { :value => lang, :expires => 24.hour.from_now }
      end
      if lang.nil? || lang.empty?
        lang = ","
      end
      lang
    end

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

    def save_search_log(query, products)
      searchlog = Searchlog.new
      searchlog.search = query
      if products.nil? || products.count == 0
        searchlog.results = 0  
      else
        searchlog.results = products.count
      end
      searchlog.save
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