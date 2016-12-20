class LandingPageController < ApplicationController


  def index
    @user = User.new
    @languages = Product::A_LANGS_FILTER
    @most_followed = Product.all.desc(:followers).limit(10)

    if EnterpriseService.activated?
      render :layout => 'application_lp'
    else
      render :layout => 'enterprise_activation'
    end
  end


end
