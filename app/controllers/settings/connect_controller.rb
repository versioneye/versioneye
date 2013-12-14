class Settings::ConnectController < ApplicationController

  before_filter :authenticate

  def index
    @user = current_user
  end

  def disconnect
    user = current_user
    service = params[:service]
    if service && service.eql?('twitter')
      user.twitter_token = nil
      user.twitter_secret = nil
    elsif service && service.eql?('github')
      user.github_token = nil
      user.github_scope = nil
    end
    user.save
    redirect_to settings_connect_path
  end

end
