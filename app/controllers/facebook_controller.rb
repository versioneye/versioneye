class FacebookController < ApplicationController

  layout "plain"

  def start
    code = params['code']

    domain = 'https://graph.facebook.com'
    uri = '/oauth/access_token'
    query = 'client_id=230574627021570&'
    query += 'redirect_uri=http://versioneye-beta.com/facebook/start&'
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
      user = User.find_by_fb_id json_user['id']
      if user.nil?
        user = User.find_by_fb_id(json_user['email'])
        if user.nil?
          user = User.new
          user.update_from_fb_json json_user
        end
      end
      user.fb_token = token
      user.save
      user
    end

end