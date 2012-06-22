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

  def sitemap01
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap01.xml'
  end
  def sitemap02
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap02.xml'
  end
  def sitemap03
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap03.xml'
  end
  def sitemap04
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap04.xml'
  end
  def sitemap05
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap05.xml'
  end
  def sitemap06
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap06.xml'
  end
  def sitemap07
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap07.xml'
  end
  def sitemap08
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap08.xml'
  end
  def sitemap09
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap09.xml'
  end
  def sitemap10
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap10.xml'
  end
  def sitemap11
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap11.xml'
  end
  def sitemap12
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap12.xml'
  end
  def sitemap13
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap13.xml'
  end
  def sitemap14
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap14.xml'
  end
  def sitemap15
    redirect_to 'https://s3.amazonaws.com/veye_assets/sitemap15.xml'
  end

end