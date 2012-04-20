class TwitterController < ApplicationController

  layout "plain"

  def forward 
    consumer_key = 'XCXPzp6GGZcFfCw2UhxocA'
    consumer_secret = 'so1T6l4nrLaY5IZEfIFzb8CtkrmNwe0I7K6F4a3oZx4'
    oauth = OAuth::Consumer.new(consumer_key, consumer_secret, { :site => "http://twitter.com" })
    p "oauth: #{oauth}"
    
    url = "http://versioneye.com/auth/twitter/callback"
    request_token = oauth.get_request_token(:oauth_callback => url)
    p "request_toke: #{request_token}"
    
    session[:token] = request_token.token
    session[:secret] = request_token.secret
    
    redirect_to request_token.authorize_url
  end

  def callback
    consumer_key = 'XCXPzp6GGZcFfCw2UhxocA'
    consumer_secret = 'so1T6l4nrLaY5IZEfIFzb8CtkrmNwe0I7K6F4a3oZx4'
    oauth = OAuth::Consumer.new(consumer_key, consumer_secret, { :site => "http://twitter.com" })
    
    request_token = OAuth::RequestToken.new(oauth, session[:token], session[:secret])
    access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])

    # Get account details from Twitter
    response = oauth.request(:get, '/account/verify_credentials.json', access_token, { :scheme => :query_string })

    # Then do stuff with the details
    @user_info = JSON.parse(response.body)
    p "#{@user_info}"
    logger.info "user_info: #{@user_info}"
  end

  def callback2
    code = params['code']
    p "twitter callback. code: #{code}"

    domain = 'https://graph.facebook.com'
    uri = '/oauth/access_token'
    query = 'client_id=230574627021570&'
    query += 'redirect_uri='
    query += configatron.server_url 
    query += '/twitter/start&'
    query += 'client_secret=d27fb4a5d443f29cfdbddd79638c91a8&'
    query += 'code=' + code
    link = domain + uri + '?' + query

    response = HTTParty.get(URI.encode(link))

    data = response.body
    access_token = data.split("=")[1]

    user = get_user_for_token( access_token )
    if !user.nil?
      sign_in user
    end
  end

  private

    def get_user_for_token(token)
      json_user = JSON.parse HTTParty.get('https://graph.facebook.com/me?access_token=' + URI.escape(token)).response.body
      user = User.find_by_fb_id( json_user['id'] )
      if user.nil?
        user = User.find_by_email(json_user['email'])
        if user.nil?
          user = User.new
          user.update_from_fb_json(json_user, token)
          user.save
        else
          user.update_column(:fb_id, json_user['id'])
        end
      end      
      user.update_column(:fb_token, token)
      user
    end

end