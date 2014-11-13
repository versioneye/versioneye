class Settings::ConnectController < ApplicationController

  before_filter :authenticate

  def index
    @user = current_user
  end

  def disconnect
    user = current_user
    service = params[:service]
    if service && service.eql?('github')
      user.github_token = nil
      user.github_scope = nil
      user.github_repos.delete_all
      cookies.delete(:gh_scope)
    elsif service && service.eql?('bitbucket')
      user[:bitbucket_token] = nil
      user[:bitbucket_scope] = nil
      user[:bitbucket_secret] = nil
      user.bitbucket_repos.delete_all
    end
    user.save
    redirect_to settings_connect_path
  end

end
