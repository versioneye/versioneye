class Auth::BitbucketController < ApplicationController
  before_filter :set_locale

  def callback
    if session.has_key?(:request_token)
      oauth_verifier = params[:oauth_verifier]
      oauth_token = params[:oauth_token]

      access_token = session[:request_token].get_access_token(
        oauth_consumer_key: Bitbucket.consumer_key, 
        oauth_verifier: oauth_verifier,
        oauth_token: oauth_token
      )
 
      user_info = Bitbucket.user(access_token.token, access_token.secret)
      user = User.find_by_bitbucket_id(user_info[:username])

      if signed_in?
        #connect accounts and update info
        current_user.update_from_bitbucket_json(user_info, access_token.token, access_token.secret)
        current_user.save
        redirect_to settings_connect_path and return
      end

      if user.nil?
        cookies.permanent.signed[:access_token] = access_token.token
        cookies.permanent.signed[:access_token_secret] = access_token.secret
        redirect_to auth_bitbucket_new_path(email: session[:email], promo_code: session[:promo_code]) and return
      elsif user.activated?
        user.update_from_bitbucket_json(user_info, access_token.token, access_token.secret)
        user.save
        sign_in user
        redirect_to settings_connect_path and return
      else
        flash[:error] = "Your account is no activated. Please check your email account."
      end
    end

    session.clear
    redirect_to signin_path 
    return
  end

  def signin
    if signed_in?
      flash[:error] = "You already have active Bitbucket session. Please log out to switch accounts."
      redirect_to settings_connect_path and return
    end

    callback_url =  auth_bitbucket_callback_url
    request_token = Bitbucket.request_token(callback_url)
    session[:request_token] = request_token
    redirect_to request_token.authorize_url(oauth_callback: callback_url)
    return
  end

  def connect
    if not signed_in?
      flash[:error] = "You have to signed in to connect Bibucket account with your VersionEye account."
      redirect_to signin_path and return
    end

    callback_url =  auth_bitbucket_callback_url
    request_token = Bitbucket.request_token(callback_url)
    session[:request_token] = request_token
    redirect_to request_token.authorize_url(oauth_callback: callback_url)
  end

  def new
    @email = params[:email]
    @terms = params[:terms]
    @promo = params[:promo_code]

    if !User.email_valid?(@email)
      flash[:error] = "The E-Mail address is already taken. Please choose another E-Mail."
      init_variables_for_new_page
      render auth_bitbucket_new_path and return
    elsif !@terms.eql?("1")
      flash[:error] = "You have to accept the Conditions of Use AND the Data Aquisition."
      init_variables_for_new_page
      render auth_bitbucket_new_path and return
    end
    
    callback_url = auth_bitbucket_callback_url
    request_token = Bitbucket.request_token(callback_url) 
    session[:email] = @email
    session[:terms] = @terms
    session[:promo_code] = @promo
    session[:request_token] = request_token
    redirect_to request_token.authorize_url(oauth_callback: callback_url)
  end

  def create
    @email = params[:email]
    @terms = params[:terms]
    @promo = params[:promo_code]
    access_token = cookies.signed[:access_token]
    access_secret = cookies.signed[:access_token_secret]


    Rails.logger.debug("Email: #{@email}, terms: #{@terms}")
    if @email.nil? or @terms.nil?
      error_msg = "Authorization failed. Please try again if it keeps failing then please contact with us."
      Rails.logger.error error_msg 
      flash[:error] = error_msg 
      redirect_to auth_bitbucket_new_path and return
    end

    if access_token.to_s.empty? or access_secret.to_s.empty?
      error_msg = "Authorization failed. Our service did not get valid access token from Bitbucket."
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
end
