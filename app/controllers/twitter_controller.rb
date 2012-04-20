class TwitterController < ApplicationController

  @@consumer_key = 'QUC41adGEitJRMMyBJ7w'
  @@consumer_secret = '5hI3nV0KLCXsT96gdTV6ntQ76wss76l9yXI4lKmNrCI'

  def forward 
    oauth = oauth_consumer
    
    url = "http://versioneye.com/auth/twitter/callback"
    request_token = oauth.get_request_token(:oauth_callback => url)
    
    session[:token] = request_token.token
    session[:secret] = request_token.secret
    
    redirect_to request_token.authorize_url
  end

  def callback
    logger.info "twitter callback"
    session[:verifier] = params[:oauth_verifier]
    json_user = fetch_json_user(session[:token], session[:secret], verifier )

    logger.info "user_info: #{json_user}"

    user = User.find_by_twitter_id( json_user['id'] )
    if !user.nil?
      user.update_column(:twitter_token, access_token)
      user.save
      sign_in user
      redirect_back_or( "/news" )
      return 
    else
      session[:twitter_user] = json_user
      session[:access_token] = access_token
      @user = User.new
      render "new"
    end
  end

  def new 
    @email = ""
    @terms = false
    @datenerhebung = false
  end

  def create    
    @email = params[:email]
    @terms = params[:terms]
    @datenerhebung = params[:datenerhebung]
    
    if !User.email_valid?(@email)
      flash.now[:error] = "The E-Mail address is already taken. Please choose another E-Mail."
      render 'new'
    elsif !@terms.eql?("1") || !@datenerhebung.eql?("1")
      flash.now[:error] = "You have to accept the Conditions of Use AND the Data Aquisition."
      render 'new'
    else    
      user_info = fetch_json_user(session[:token], session[:secret], session[:verifier] )
      if user_info == nil || user_info.empty?
        flash.now[:error] = "An error occured. Your Twitter token is not anymore available. Please try again later."
        logger.error "An error occured. Your Twitter token is not anymore available. Please try again later."
        render 'new'
        return
      end
      user = User.new
      user.update_from_twitter_json(user_info, session[:access_token])
      user.email = @email
      user.terms = true
      user.datenerhebung = true
      user.create_verification
      if user.save
        user.send_verification_email
        User.new_user_email(user)
        sign_in user
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
      OAuth::Consumer.new(@@consumer_key, @@consumer_secret, { :site => "http://twitter.com" })
    end

    def fetch_json_user(token, secret, verifier )
      oauth = oauth_consumer
      request_token = OAuth::RequestToken.new( oauth, token, secret )
      access_token = request_token.get_access_token(:oauth_verifier => verifier)
      response = oauth.request(:get, '/account/verify_credentials.json', access_token, { :scheme => :query_string })
      json_user = JSON.parse(response.body)
    end

end