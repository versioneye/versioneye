require 'oauth'

class Bitbucket
  @@api_url = "https://bitbucket.org"
  @@api_v2_path = "/api/2.0"
  @@api_v1_path = "/api/1.0"
  
  #TODO: refactor out 
  @@api_key = "wW9SUTCKmMDjzFeaXU"
  @@api_secret = "uQttxDwB7sPrvFnvEkAwwg5TLBdTG4jC"


  def self.consumer_key 
   @@api_key 
  end
  
  def self.init_oauth_client
    OAuth::Consumer.new(@@api_key, @@api_secret, 
                       site: @@api_url,
                       request_token_path: "/api/1.0/oauth/request_token",
                       authorize_path: "/api/1.0/oauth/authenticate",
                       access_token_url: "/api/1.0/oauth/access_token")
  end

  def self.request_token(callback_url)
    oauth = init_oauth_client
    oauth.get_request_token(oauth_callback: callback_url)
  end

  def self.user(token, secret)
    path = "#{@@api_v1_path}/user"
    response = get_json(path, token, secret)
    response[:user] unless response.nil?
  end

  def self.get_json(path, token, secret, params = {}, headers = {})
    url = "#{@@api_url}/#{path}"
    oauth = init_oauth_client
    token = OAuth::AccessToken.new(oauth, token, secret)
    oauth_params = {consumer: oauth, token: token, request_uri: url}
    request_headers = {"User-Agent" => "Chrome 28 (info@versioneye.com)"}
    request_headers.merge! headers

    response = token.get(path, request_headers)
    begin
      JSON.parse(response.body, symbolize_names: true) 
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error "Got status: #{response.code} #{response.message} body: #{response.body}"
      Rails.logger.error e.backtrace.join("\n")
    end
 end
end
