class PricingController < ApplicationController


  def index 
    @plan = current_user.plan if signed_in?
  end 


end
