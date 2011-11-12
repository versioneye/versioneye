class PageController < ApplicationController

  def contact
  end

  def about
  end

  def home
    if signed_in?
      
    else
#      @forShow = Measurement.all
#      @akws = Akw.all
    end
  end

  def terms
  end

  def signin
  end

  def signup
  end

end