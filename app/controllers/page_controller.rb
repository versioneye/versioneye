class PageController < ApplicationController

  def routing_error
    path = request.fullpath
    if path.match(/\/version\//)
      path.gsub!("/version/", "/")
      redirect_to path
    end
    redirect_to "/"
  end

  def legacy_route
    key     = params[:key]
    version = params[:version]
    key = key.gsub("~", ".").gsub("--", "/").gsub(":", "/")
    if version
      version = version.gsub("~", ".").gsub("--", "/").gsub(":", "/")
    end
    product = Product.find_by_key key
    if product
      version = product.version if version.nil?
      redirect_to package_version_path( product.language_esc, product.to_param, version )
      return
    end
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
    if language.empty?
      redirect_to "/"
    else
      redirect_to "/#{language}/#{key}"
    end
    return
  end

  def disclaimer
    redirect_to "http://www.disclaimer.de/disclaimer.htm?farbe=FFFFFF/000000/000000/000000"
  end

  def contact
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

  def newest
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

end
