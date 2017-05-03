class Settings::LinksController < ApplicationController

  before_action :authenticate

  def index
    @userlinkcollection = Userlinkcollection.find_all_by_user( current_user.id )
    if @userlinkcollection.nil?
      @userlinkcollection = Userlinkcollection.new
    end
  end

  def update
    @userlinkcollection = Userlinkcollection.find_all_by_user( current_user.id )
    if @userlinkcollection.nil?
      @userlinkcollection = Userlinkcollection.new
    end
    @userlinkcollection.github        = params[:github]
    @userlinkcollection.stackoverflow = params[:stackoverflow]
    @userlinkcollection.linkedin      = params[:linkedin]
    @userlinkcollection.xing          = params[:xing]
    @userlinkcollection.twitter       = params[:twitter]
    @userlinkcollection.facebook      = params[:facebook]
    @userlinkcollection.user_id       = current_user.id
    if @userlinkcollection.save
      flash[:success] = 'Profile updated.'
    else
      flash[:error] = 'Something went wrong. Please try again later.'
    end
    redirect_to settings_links_path()
  end

end
