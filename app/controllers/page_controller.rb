class PageController < ApplicationController

  def routing_error
    p "routing error path: #{params[:path]}"
    redirect_to "/"
  end

  def disclaimer
    redirect_to "http://www.disclaimer.de/disclaimer.htm?farbe=FFFFFF/000000/000000/000000"
  end

  def pricing
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

  def sitemap_1
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_1.xml'
  end
  def sitemap_2
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_2.xml'
  end
  def sitemap_3
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_3.xml'
  end
  def sitemap_4
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_4.xml'
  end
  def sitemap_5
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_5.xml'
  end
  def sitemap_6
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_6.xml'
  end
  def sitemap_7
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_7.xml'
  end
  def sitemap_8
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_8.xml'
  end
  def sitemap_9
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_9.xml'
  end
  def sitemap_10
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_10.xml'
  end
  def sitemap_11
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_11.xml'
  end
  def sitemap_12
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_12.xml'
  end
  def sitemap_13
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_13.xml'
  end
  def sitemap_14
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_14.xml'
  end
  def sitemap_15
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_15.xml'
  end
  def sitemap_16
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap_16.xml'
  end

end