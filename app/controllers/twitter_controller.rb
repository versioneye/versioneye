class TwitterController < ApplicationController

  def forward 
    oauth = oauth_consumer
    url = "https://www.versioneye.com/auth/twitter/callback"
    request_token = oauth.get_request_token(:oauth_callback => url)
    session[:token] = request_token.token
    session[:secret] = request_token.secret
    redirect_to request_token.authorize_url
  rescue => e 
    p "#{e}"
    e.backtrace.each do |message| 
      p " - #{message}"
    end
    flash[:error] = "An error occured. Please contact the VersionEye Team."
    redirect_to "/signup"
  end

  def callback
    oauth_verifier = params[:oauth_verifier]
    if oauth_verifier.nil? || oauth_verifier.empty?
      redirect_to "/signup"
      return
    end

    oauth = oauth_consumer    
    access_token = fetch_access_token( oauth, session[:token], session[:secret], oauth_verifier)
    session[:token] = nil
    session[:secret] = nil
    session[:access_token] = access_token
    json_user = fetch_json_user( oauth, access_token )

    if signed_in?
      update_current_user(current_user, json_user, access_token)
      redirect_to settings_connect_path
      return 
    end 

    json_user_id = json_user['id']
    user = nil 
    if json_user_id
      user = User.find_by_twitter_id( json_user_id )
    end
    if user
      update_current_user(user, json_user, access_token)
      sign_in user
      redirect_back_or( "/user/projects" )
    else
      redirect_to "http://versioneye.com/auth/twitter/new"
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
      oauth = oauth_consumer
      access_token = session[:access_token]
      user_info = fetch_json_user( oauth, access_token )
      if user_info == nil || user_info.empty?
        flash.now[:error] = "An error occured. Your Twitter token is not anymore available. Please try again later."
        logger.error "An error occured. Your Twitter token is not anymore available. Please try again later."
        render 'new'
        return
      end
      user = User.new
      user.update_from_twitter_json(user_info, access_token.token, access_token.secret)
      user.email = @email
      user.terms = true
      user.datenerhebung = true
      user.create_verification
      if user.save
        user.send_verification_email
        User.new_user_email(user)
        sign_in user
        session[:access_token] = nil
        render 'create'
      else 
        flash.now[:error] = "An error occured. Please contact the VersionEye Team."
        logger.error "An error occured. Please contact the VersionEye Team."
        render 'new'
      end
    end
  end

  private 

    def oauth_consumer
      OAuth::Consumer.new(Settings.twitter_consumer_key, 
                          Settings.twitter_consumer_secret, 
                          :site => "https://api.twitter.com", 
                          :request_token_path => '/oauth/request_token', 
                          :authorize_path     => '/oauth/authorize',
                          :access_token_path  => '/oauth/access_token')
    end

    def fetch_access_token( oauth, token, secret, verifier )
      request_token = OAuth::RequestToken.new( oauth, token, secret )
      request_token.get_access_token(:oauth_verifier => verifier)
    end

    def fetch_json_user( oauth, access_token )
      response = oauth.request(:get, '/1.1/account/verify_credentials.json', access_token, { :scheme => :query_string })
      json_user = JSON.parse(response.body)
    end

    def update_twitter_status(token, secret)
      logger.info "---- update_twitter_status ------------------"
      client = TwitterOAuth::Client.new(
                  :consumer_key => Settings.twitter_consumer_key, 
                  :consumer_secret => Settings.twitter_consumer_secret, 
                  :token => token, 
                  :secret => secret)
      if client.authorized?
        client.update("I just signed up @VersionEye to keep track of my software libraries.")
      end
    end

    def update_current_user(user, json_user, access_token)
      user.twitter_id = json_user['id']
      user.twitter_token = access_token.token
      user.twitter_secret = access_token.secret
      user.save 
    end

end