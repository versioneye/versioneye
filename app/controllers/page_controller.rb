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

  def site_map_01
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_1.xml'
  end
  def site_map_02
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_2.xml'
  end
  def site_map_03
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_3.xml'
  end
  def site_map_04
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_4.xml'
  end
  def site_map_05
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_5.xml'
  end
  def site_map_06
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_6.xml'
  end
  def site_map_07
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_7.xml'
  end
  def site_map_08
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_8.xml'
  end
  def site_map_09
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_9.xml'
  end
  def site_map_10
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_10.xml'
  end
  def site_map_11
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_11.xml'
  end
  def site_map_12
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_12.xml'
  end
  def site_map_13
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_13.xml'
  end
  def site_map_14
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_14.xml'
  end
  def site_map_15
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_15.xml'
  end
  def site_map_16
    redirect_to 'https://s3.amazonaws.com/veye_assets/site_map_16.xml'
  end

end