class ProductsController < ApplicationController

  
  require 'will_paginate/array'

  
  before_filter :authenticate                  , :only => [:edit, :edit_links, :edit_licenses, :update, :delete_link, :delete_license, :edit_keywords, :delete_keyword, :add_keyword]
  before_filter :maintainer?                   , :only => [:edit, :edit_links, :edit_licenses, :edit_versions, :edit_keywords, :update, :delete_link, :delete_license, :delete_version, :delete_keyword, :add_keyword]
  before_filter :check_redirects_package       , :only => [:show]
  before_filter :check_redirects_package_visual, :only => [:show_visual]
  before_filter :check_refer                   , :only => [:index]



  def search
    @query   = do_parse_search_input( params[:q] )
    @groupid = params[:g]
    @lang    = get_lang_value( params[:lang] )
    if (@query.nil? || @query.empty?) && (@groupid.nil? || @groupid.empty?)
      flash.now[:error] = 'Please give us some input. Type in a value for name.'
    elsif @query.include?('%')
      flash.now[:error] = 'the character % is not allowed'
    else
      languages = get_language_array(@lang)
      @products = ProductService.search( @query, @groupid, languages, params[:page])
    end
    @languages = Product::A_LANGS_FILTER
  end


  def show
    lang     = Product.decode_language( params[:lang] )
    prod_key = Product.decode_prod_key( params[:key]  )
    version  = Version.decode_version ( params[:version] )
    build    = Version.decode_version ( params[:build] )

    @product = ProductService.fetch_product lang, prod_key, version
    return if @product.nil?

    # if product language is different from language in param than do a redirect!
    if !@product.nil? && !lang.nil? && lang.to_s.casecmp( @product.language.to_s ) != 0
      redirect_to package_version_path( @product.language_esc.downcase, @product.to_param, @product.version ) and return
    end

    if !build.to_s.strip.empty?
      params[:version] = version = "#{version}:#{build}"
      params[:build] = nil
      redirect_to( {:action => 'show'}.merge(params) ) and return
    end

    if version.nil? || (!attach_version(@product, version))
      add_default_version @product if @product.version.to_s.empty?
      params[:version] = @product.version
      redirect_to( {:action => 'show'}.merge(params) ) and return
    end

    @version             = fetch_version @product
    @versioncomment      = Versioncomment.new
    @versioncommentreply = Versioncommentreply.new
  rescue => e
    flash[:error] = "An error occured (#{e.message}). Please contact the VersionEye Team."
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end


  def show_visual
    lang = Product.decode_language( params[:lang] )
    key  = Product.decode_prod_key( params[:key]  )
    version  = Version.decode_version ( params[:version] )
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


  # Dependency Badge
  # send_file "app/assets/images/badges/dep_#{badge}.png", :type => "image/png", :disposition => 'inline'
  def badge
    language = Product.decode_language params[:lang]
    prod_key = Product.decode_prod_key params[:key]
    version  = Version.decode_version  params[:version]
    key = "#{language}:::#{prod_key}:::#{version}"
    badge = BadgeService.badge_for key 
    send_data badge.svg, :type => "image/svg+xml", :disposition => 'inline'
  rescue => e 
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end


  def ref_badge
    language = Product.decode_language params[:lang]
    prod_key = Product.decode_prod_key params[:key]
    
    key = "#{language}:::#{prod_key}:::ref"
    badge = BadgeRefService.badge_for key 
    send_data badge.svg, :type => "image/svg+xml", :disposition => 'inline'
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end

  
  def references
    language   = Product.decode_language params[:lang]
    prod_key   = Product.decode_prod_key params[:key]
    page       = parse_page params[:page]

    @product   = fetch_product language, prod_key
    if @product.nil?
      render :text => "This page doesn't exist", :status => 404 and return
    end

    reference = ReferenceService.find_by @product.language, prod_key
    if reference.nil?
      @products = paged_products 1, nil, 0
      return
    end

    products   = reference.products page
    if products.nil? || products.empty?
      @products = paged_products 1, nil, reference.ref_count
      return
    end

    paged_products page, products, reference.ref_count
  rescue => e
    flash[:error] = "An error occured. Please contact the VersionEye Team."
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end


  def project_usage 
    language   = Product.decode_language params[:lang]
    prod_key   = Product.decode_prod_key params[:key]

    @product   = fetch_product language, prod_key
    if @product.nil?
      render :text => "This page doesn't exist", :status => 404 and return
    end

    @project_ids = ReferenceService.project_references language, prod_key
  rescue => e
    flash[:error] = "An error occured. Please contact the VersionEye Team."
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')      
  end


  def edit
  end

  def edit_links
  end

  def edit_licenses
  end

  def edit_versions
  end

  def edit_keywords
  end


  def update
    description     = params[:description_manual]
    license         = params[:license]
    license_link    = params[:licenseLink]
    license_version = params[:licenseVersion]
    if license_version.to_s.eql?("ALL")
      license_version = nil
    end
    twitter_name    = params[:twitter_name]
    link_url        = params[:link_url]
    link_name       = params[:link_name]
    if @product.nil?
      flash[:error] = "An error occured. Please try again later."
      redirect_to package_version_path(@product.language_esc, @product.to_param, @product.version)
      return
    end
    if description && !description.empty?
      @product.description_manual = description
      @product.save
      Auditlog.add current_user, 'Product', @product.id.to_s, "Updated description. New Value: #{description}"
      flash[:success] = "Description updated."
    elsif !license.to_s.empty?
      license = License.find_or_create @product.language, @product.prod_key, license_version, license, license_link
      Auditlog.add current_user, 'Product', @product.id.to_s, "Added License #{license}"
      flash[:success] = "License updated."
    elsif twitter_name && !twitter_name.empty?
      @product.twitter_name = twitter_name
      @product.save
      Auditlog.add current_user, 'Product', @product.id.to_s, "Added Twitter name #{twitter_name}"
      flash[:success] = "Twitter name updated."
    elsif link_url && !link_url.empty?
      versionlink = Versionlink.new
      versionlink.language = @product.language
      versionlink.prod_key = @product.prod_key
      versionlink.link = link_url
      versionlink.name = link_name
      versionlink.manual = true
      versionlink.save
      Auditlog.add current_user, 'Product', @product.id.to_s, "Added Link #{link_url}."
      flash[:success] = "New link added."
    end
    redirect_to :back
  end


  def delete_link
    lang     = Product.decode_language( params[:lang] )
    key      = Product.decode_prod_key params[:key]
    link_url = params[:link_url]
    Versionlink.remove_project_link( lang, key, link_url )
    Auditlog.add current_user, 'Product', @product.id.to_s, "Remove Link #{link_url}"
    flash[:success] = "Link removed."
    redirect_to :back
  end


  def delete_license
    license_id = params[:license_id]
    license = License.find( license_id )
    if license
      Auditlog.add current_user, 'Product', @product.id.to_s, "Remove License #{license.name} - #{license.to_s}"
      license.remove
      flash[:success] = "License removed."
    end
    redirect_to :back
  end


  def delete_version
    if @product.remove_version params[:version]
      Auditlog.add current_user, 'Product', @product.id.to_s, "Remove Version #{params[:version]}"
      flash[:success] = "Version removed."
    end
    redirect_to :back
  end


  def delete_keyword
    keyword = params[:keyword]
    @product.remove_tag keyword
    @product.save 
    flash[:success] = "Keyword removed."
    redirect_to :back
  end


  def add_keyword 
    keyword = params[:keyword]
    @product.add_tag keyword
    @product.save 
    flash[:success] = "Keyword added."
    redirect_to :back
  end


  def auditlogs
    language    = Product.decode_language params[:lang]
    product_key = Product.decode_prod_key params[:key]
    @product    = fetch_product language, product_key
  end


  def follow
    lang_param       = params[:product_lang]
    @prod_key_param  = params[:product_key]
    product_key      = Product.decode_prod_key @prod_key_param
    language         = Product.decode_language lang_param
    follow           = ProductService.follow language, product_key, current_user
    @prod_lang_param = Product.encode_language language
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
    @prod_lang_param = Product.encode_language language
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
      next if product.nil?
      results << format_autocomplete(product)
      break if index > 9
    end
    render :json => results
  end


  private


    def fetch_product language, prod_key
      product = ProductService.fetch_product language, prod_key
      if product.nil? && language.eql?(Product::A_LANGUAGE_JAVA)
        product = Product.fetch_product Product::A_LANGUAGE_CLOJURE, prod_key
      end
      product
    end


    def parse_page page
      return 1 if page.to_s.empty?
      return 1 if page.to_i < 1
      page
    end


    def format_autocomplete(product)
      return {} if product.nil?
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

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end

    def paged_products page = 1, products, count
      products = [] if products.nil?
      per_page   = 30
      pre_amount = (page.to_i - 1) * per_page
      pre        = Array.new pre_amount
      @products  = pre + products
      @products  = @products.paginate(:page => page, :per_page => per_page)
      @products.total_entries = count
      @products
    end

end
