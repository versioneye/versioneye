class Auth::GithubController < ApplicationController

  before_filter :set_locale

  def callback
    code      = params['code']
    token     = Github.token code
    json_user = Github.user token

    if signed_in?
      update_user json_user, token
      redirect_to settings_connect_path
      return
    end

    user = user_for_github_id( json_user )
    if user && user.activated?
      user.github_token = token
      user.save
      sign_in user
      redirect_back_or user_packages_i_follow_path
      return
    end

    if user && !user.activated?
      flash[:error] = 'Your account is not activated. Did you click the verification link in the email we sent to you?'
      redirect_to signin_path
      return
    end

    email = primary_email token
    email_available = User.email_valid?(email)
    email_already_taken = !email_available

    if user.nil? && email_already_taken # than ask for a new email
      flash.now[:error] = "The email address is already taken."
      prepare_new_page user, token
      render auth_github_new_path
      return
    end

    if user.nil? && email_available # Than login the user
      user = new_user( token, email, true )
      if user.save
        login user
      else
        flash.now[:error] = 'An error occured.'
        init_variables_for_new_page user, email
        render auth_github_new_path
      end
    end
  end


  def create
    @email = params[:email]
    @terms = params[:terms]
    @promo = params[:promo_code]

    token = cookies.signed[:github_token]
    if token == nil || token.empty?
      flash.now[:error] = 'An error occured. Your GitHub token is not available anymore. Please contact the VersionEye team.'
      render auth_github_new_path and return
    end

    unless @terms.eql?('1')
      flash.now[:error] = 'You have to accept the Conditions of Use AND the Data Aquisition.'
      init_variables_for_new_page nil, @email
      render auth_github_new_path and return
    end

    user = new_user( token, @email, @terms )
    user.create_verification
    if user.save
      user.send_verification_email
      login user, @promo
      return
    end

    flash.now[:error] = 'An error occured.'
    init_variables_for_new_page user, @email
    render auth_github_new_path
  end


  private


    def primary_email token
      emails = Github.emails token
      primary_email = emails.first[:email]
      emails.each do |em|
        if em[:primary] == true
          primary_email = em[:email]
        end
      end
      primary_email
    rescue => e
      Rails.logger.error e.message
      nil
    end


    def init_variables_for_new_page user = nil, email = nil
      @user = user
      @user = User.new({:email => email}) if user.nil?
      @email = email
      @terms = false
      @promo = cookies.signed[:promo_code]
    end


    def update_user(json_user, token)
      user = current_user
      user.github_id = json_user['id']
      user.github_token = token

      update_scope user, token

      # The next line is mandatory otherwise the private
      # repos don't get fetched immediately (reiz)
      user.github_repos.delete_all
      user.save
    end


    def update_scope user, token, save_user == false
      scopes = Github.oauth_scopes( token )
      if scopes && scopes.is_a?(Array)
        user.github_scope = scopes.join ', '
        user.save if save_user == true
      end
    end


    def user_for_github_id(json_user)
      return nil if json_user.nil?
      return nil if json_user['id'].nil?
      user = User.find_by_github_id( json_user['id'].to_s )
      return nil if user.nil?
      user
    end


    def new_user token, email, terms
      json_user = Github.user token
      user      = User.new
      user.update_from_github_json( json_user, token )
      user.email         = email
      user.terms         = terms
      user.datenerhebung = terms
      update_scope( user, token )
      user
    end


    def prepare_new_page user, token
      cookies.permanent.signed[:github_token] = token
      email = primary_email token
      init_variables_for_new_page user, email
    end


    def login user, promo = nil
      sign_in( user )
      update_scope user, user.github_token, true
      check_promo_code promo, user
      cookies.delete(:promo_code)
      cookies.delete(:github_token)
      redirect_back_or( user_packages_i_follow_path )
    end

end
