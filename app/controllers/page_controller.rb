class PageController < ApplicationController

  def routing_error
    path = request.fullpath
    match = false
    if path.match(/\/version\//)
      path.gsub!("/version/", "/")
      match = true
    end
    if path.match(/\/product\//)
      path.gsub!("product", "package")
      match = true
    end
    if match == false
      logger.error "Routing error for path: #{params[:path]}"
      path = "/"
    end
    redirect_to path
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
