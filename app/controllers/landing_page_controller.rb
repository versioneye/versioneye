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


  def create
    email = params[:landing_page][:email]

    user = User.find_by_email email
    if user.nil? 
      user = User.new
      user.email = email
      user.username = "lp_newsletter_#{create_random_value}"
      user.fullname = user.username
      user.terms = true
      user.datenerhebung = true
    end

    if user.save 
      p "saved #{email}"
      flash[:success] = "We will notify about the relaunch"
    else
      p "not saved #{email}"
      flash[:error] = "Something went wrong"
    end
    redirect_to '/'
  end


  private 


    def create_random_value
      chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      value = ""
      10.times { value << chars[rand(chars.size)] }
      value
    end


end
