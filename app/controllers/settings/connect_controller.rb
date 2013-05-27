class Settings::ConnectController < ApplicationController

  before_filter :authenticate
  force_ssl if Rails.env.production?

  def index
    @user = current_user
  end

  def disconnect
    user = current_user
    service = params[:service]
    if service && service.eql?("twitter")
      user.twitter_id = nil
      user.twitter_token = nil
      user.twitter_secret = nil
    elsif service && service.eql?("facebook")
      user.fb_id = nil
      user.fb_token = nil
    elsif service && service.eql?("github")
      user.github_id = nil
      user.github_token = nil
      user.github_scope = nil
    end
    user.save
    redirect_to settings_connect_path
  end

end
