class PageController < ApplicationController

  def routing_error
    path = request.fullpath
    if path.match(/\/version\//)
      path.gsub!("/version/", "/")
    else
      path = "/"
    end
    redirect_to path
  end

  def legacy_route
    path = "/"
    key     = params[:key]
    version = params[:version]
    key = parse_param key
    if version
      version = parse_param version
    end
    product = Product.find_by_key key
    if product
      version = product.version if version.nil?
      path = "/#{product.language_esc}/#{product.to_param}/#{version}"
    else
      hash = fetch_lang_and_key( key )
      language = hash['language']
      key = hash['key']
      if !language.empty?
        product = Product.fetch_product language, key
        if product
          path = "/#{product.language_esc}/#{product.to_param}/#{version}"
        end
      end
    end
    redirect_to path.gsub("//", "/")
  end

  def legacy_badge_route
    path    = "/"
    key     = params[:key]
    version = params[:version]
    key     = parse_param key
    if version
      version = parse_param version
    end
    product = Product.find_by_key key
    if product
      version = product.version if version.nil?
      path    = "/#{product.language_esc}/#{product.to_param}/#{version}/badge.png"
    else
      hash     = fetch_lang_and_key( key )
      language = hash['language']
      key      = hash['key']
      if !language.empty?
        product = Product.fetch_product language, key
        if product
          path = "/#{product.language_esc}/#{product.to_param}/#{version}/badge.png"
        end
      end
    end
    redirect_to path.gsub("//", "/")
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

  def disclaimer
    redirect_to "http://www.disclaimer.de/disclaimer.htm?farbe=FFFFFF/000000/000000/000000"
  end

  def contact
  end

  def faq
  end

  def about
  end

  def impressum
  end

  def home
  end

  def terms
  end

  def signin
  end

  def signup
  end

  def apijson
  end

  def logos
  end

  def sitemap_1
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_00_1.xml'
  end
  def sitemap_2
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_00_2.xml'
  end
  def sitemap_3
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_00_3.xml'
  end
  def sitemap_4
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_00_4.xml'
  end

  private

    def parse_param key
      key.gsub("~", ".").gsub("--", "/").gsub(":", "/")
    end

    def fetch_lang_and_key( key )
      language = ""
      if key.match(/^npm\//)
        key = key.gsub("npm\/", "")
        language = Product::A_LANGUAGE_NODEJS
      elsif key.match(/^pip\//)
        key = key.gsub("pip\/", "")
        language = Product::A_LANGUAGE_PYTHON
      elsif key.match(/^php\//)
        key = key.gsub("php\/", "")
        language = Product::A_LANGUAGE_PHP
      end
      hash = Hash.new
      hash['key'] = key
      hash['language'] = language
      return hash
    end

end
