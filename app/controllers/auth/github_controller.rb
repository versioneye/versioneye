class Auth::GithubController < ApplicationController

  before_filter :set_locale

  def callback
    code = params['code']
    if code.nil? || code.empty?
      redirect_to signup_path
      return
    end

    token     = Github.token code
    json_user = Github.user token

    if signed_in?
      update_user_scope json_user, token
      redirect_to settings_connect_path
      return
    end

    user = get_user_for_token json_user, token
    if user.nil?
      cookies.permanent.signed[:github_token] = token
      init_variables_for_new_page
      render auth_github_new_path
      return
    end

    if user.activated?
      sign_in user
      redirect_back_or user_packages_i_follow_path
      return
    end

    flash[:error] = 'Your account is not activated. Did you click the verification link in the email we sent to you?'
    redirect_to signin_path
  end

  def new
    init_variables_for_new_page
  end

  def create
    @email = params[:email]
    @terms = params[:terms]
    @promo = params[:promo_code]

    unless User.email_valid?(@email)
      flash.now[:error] = 'The E-Mail address is already taken. Please choose another E-Mail.'
      init_variables_for_new_page
      render auth_github_new_path and return
    end

    unless @terms.eql?('1')
      flash.now[:error] = 'You have to accept the Conditions of Use AND the Data Aquisition.'
      init_variables_for_new_page
      render auth_github_new_path and return
    end

    token = cookies.signed[:github_token]
    if token == nil || token.empty?
      flash.now[:error] = 'An error occured. Your GitHub token is not available anymore. Please contact the VersionEye team.'
      render auth_github_new_path and return
    end
    json_user = Github.user token
    user      = User.new
    scopes    = Github.oauth_scopes token
    scopes    = 'no_scope' if scopes.size == 0
    user.update_from_github_json( json_user, token, scopes )
    user.email         = @email
    user.terms         = true
    user.datenerhebung = true
    user.create_verification
    if user.save
      user.send_verification_email
      User.new_user_email user
      check_promo_code @promo, user
      cookies.delete(:promo_code)
      cookies.delete(:github_token)
    else
      flash.now[:error] = 'An error occured. Please contact the VersionEye Team.'
      init_variables_for_new_page
      render auth_github_new_path
    end
  end

  private

    def init_variables_for_new_page
      @user = User.new
      @terms = false
      @promo = cookies.signed[:promo_code]
    end

    def update_user_scope(json_user, token)
      user              = current_user
      user.github_id    = json_user['id']
      user.github_token = token
      scopes            = Github.oauth_scopes( token )
      scopes            = "no_scope" if scopes.size == 0
      user.github_scope = scopes
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
      user
    end

end
