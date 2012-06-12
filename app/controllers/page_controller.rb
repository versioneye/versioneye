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

end