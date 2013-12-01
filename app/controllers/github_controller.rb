class GithubController < ApplicationController

  before_filter :set_locale

  def callback
    code = params['code']
    if code.nil? || code.empty?
      redirect_to "/signup"
      return
    end

    token     = Github.token code
    json_user = Github.user token

    if signed_in?
      update_user_scope( json_user, token )
      redirect_to settings_connect_path
      return
    end

    user = get_user_for_token( json_user, token )
    if user.nil?
      cookies.permanent.signed[:github_token] = token
      @user = User.new
      render "new" and return
    end

    if user.activated?
      sign_in user
      redirect_back_or( user_packages_i_follow_path )
    else
      flash[:error] = "Your account is not activated. Did you click the verification link in the email we send you?"
      redirect_to signin_path
    end
  end

  def new
    @email = ""
    @terms = false
  end

  def create
    @email = params[:email]
    @terms = params[:terms]

    if !User.email_valid?(@email)
      flash.now[:error] = "The E-Mail address is already taken. Please choose another E-Mail."
      render 'new'
    elsif !@terms.eql?("1")
      flash.now[:error] = "You have to accept the Conditions of Use AND the Data Aquisition."
      render 'new'
    else
      token = cookies.signed[:github_token]
      if token == nil || token.empty?
        flash.now[:error] = "An error occured. Your GitHub token is not anymore available. Please try again later."
        render 'new' and return
      end
      json_user = Github.user token
      user      = User.new
      scopes    = Github.oauth_scopes( token )
      user.update_from_github_json( json_user, token, scopes )
      user.email         = @email
      user.terms         = true
      user.datenerhebung = true
      user.create_verification
      if user.save
        user.send_verification_email
        User.new_user_email(user)
        cookies.delete(:github_token)
        render 'create'
      else
        flash.now[:error] = "An error occured. Please contact the VersionEye Team."
        render 'new'
      end
    end
  end

  private

    def update_user_scope(json_user, token)
      user = current_user
      user.github_id = json_user['id']
      user.github_token = token
      user.github_scope = Github.oauth_scopes( token )
      # next line is mandatory otherwise the private repos don't get
      # fetched immediately (reiz)
      user.github_repos.delete_all
      user.save
    end

    def get_user_for_token(json_user, token)
      return nil if json_user.nil?
      return nil if json_user['id'].nil?
      user = User.find_by_github_id( json_user['id'].to_s )
      return nil if user.nil?

      user.github_token = token
      user.save
      return user
    end

end
