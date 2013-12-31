class Auth::BitbucketController < ApplicationController

  before_filter :set_locale


  def signin
    if signed_in?
      flash[:error] = "You are already signed in. If you want to connect with BitBucket, check your settings!"
      redirect_to settings_connect_path and return
    end
    connect_with_bitbucket
  end


  def connect
    if not signed_in?
      flash[:error] = "You have to signed in to connect BitBucket account with your VersionEye account."
      redirect_to signin_path and return
    end
    connect_with_bitbucket
  end


  def callback
    unless session.has_key?(:request_token)
      flash[:error] = 'An error occured. Please try again and contact the VersionEye team.'
      session.clear
      redirect_to signin_path and return
    end

    access_token = fetch_access_token params[:oauth_verifier], params[:oauth_token]
    user_info    = Bitbucket.user(access_token.token, access_token.secret)

    if signed_in?
      connect_bitbucket_with_user user_info, access_token
      redirect_to settings_connect_path and return
    end

    user = User.find_by_bitbucket_id(user_info[:username])

    if user.nil?
      cookies.permanent.signed[:access_token] = access_token.token
      cookies.permanent.signed[:access_token_secret] = access_token.secret
      redirect_to auth_bitbucket_new_path(email: session[:email], promo_code: session[:promo_code]) and return
    elsif user.activated?
      user.update_from_bitbucket_json(user_info, access_token.token, access_token.secret)
      user.save
      sign_in user
      redirect_back_or user_packages_i_follow_path and return
    else
      flash[:error] = "Your account is no activated. Please check your email account."
      redirect_to signin_path and return
    end
  end


  def new
    init_variables_for_new_page
    @email = params[:email]

    callback_url = auth_bitbucket_callback_url
    request_token = Bitbucket.request_token(callback_url)
    session[:request_token] = request_token
    # redirect_to request_token.authorize_url(oauth_callback: callback_url)
  end

  def create
    @email = params[:email]
    @terms = params[:terms]
    @promo = params[:promo_code]
    access_token = cookies.signed[:access_token]
    access_secret = cookies.signed[:access_token_secret]

    unless new_form_valid?( params )
      redirect_to auth_bitbucket_new_path and return
    end

    if access_token.to_s.empty? or access_secret.to_s.empty?
      error_msg = "Authorization failed. Our service did not get valid access token from BitBucket."
      flash[:error] = error_msg
      Rails.logger.error error_msg
      render auth_bitbucket_new_path and return
    end

    @user = create_user(@email, access_token, access_secret)
    if @user.save
      @user.send_verification_email
      User.new_user_email @user
      check_promo_code @promo, @user
      session.clear
    else
      flash[:error] = "An error occured. Please contact the VersionEye team."
      Rails.logger.error @user.errors.full_messages.to_sentence
      redirect_to auth_bitbucket_new_path
    end
  end

  private

    def new_form_valid? params
      if @email.to_s.empty?
        flash[:error] = 'The E-Mail address is mandatory!'
        init_variables_for_new_page
        return false
      end

      unless User.email_valid?(@email)
        flash[:error] = 'The E-Mail address is already taken. Please choose another E-Mail.'
        init_variables_for_new_page
        return false
      end

      unless @terms.eql?('1')
        flash[:error] = 'You have to accept the Conditions of Use AND the Data Aquisition.'
        init_variables_for_new_page
        return false
      end
      true
    end

    def fetch_access_token oauth_verifier, oauth_token
      access_token = session[:request_token].get_access_token(
        oauth_consumer_key: Bitbucket.consumer_key,
        oauth_verifier: oauth_verifier,
        oauth_token: oauth_token
      )
    end

    def create_user(email, access_token, access_secret)
      user = User.new email: email,
                      terms: true,
                      datenerhebung: true

      user_info = Bitbucket.user(access_token, access_secret)
      user.update_from_bitbucket_json(user_info, access_token, access_secret)
      user.create_verification
      user
    end

    def init_variables_for_new_page
      @user = User.new email: session[:email]
      @terms = false
      @promo = session[:promo_code]
    end

    def connect_with_bitbucket
      callback_url  = auth_bitbucket_callback_url
      request_token = Bitbucket.request_token( callback_url )
      session[:request_token] = request_token
      redirect_to request_token.authorize_url(oauth_callback: callback_url)
    end

    def connect_bitbucket_with_user user_info, access_token
      current_user[:bitbucket_id]     = user_info[:username]
      current_user[:bitbucket_login]  = user_info[:username]
      current_user[:bitbucket_token]  = access_token.token
      current_user[:bitbucket_secret] = access_token.secret
      current_user[:bitbucket_scope]  = 'read_write'
      if current_user.save
        flash[:success] = 'Your account is now connected to BitBucket.'
      else
        error_msg = "An error occured. Cant attach profile updates from BitBucket. Please contact the VersionEye team."
        Rails.logger.error "#{error_msg} Data: #{current_user.errors.full_messages.to_sentence}"
        flash[:error] = error_msg
      end
    end

end
