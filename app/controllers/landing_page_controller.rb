class LandingPageController < ApplicationController


  def index
    @user = User.new
    @languages = Product::A_LANGS_FILTER

    if EnterpriseService.activated?
      render :layout => 'application_lp'
    else
      render :layout => 'enterprise_activation'
    end
  end


end
