class FacebookController < ApplicationController

  layout "plain"

  def callback
    code = params['code']

    if code.nil? || code.empty?
      redirect_to "/signup"
      return
    end

    link2 = "https://graph.facebook.com/oauth/access_token?client_id=230574627021570&redirect_uri=https://www.versioneye.com//auth/facebook/callback&client_secret=d27fb4a5d443f29cfdbddd79638c91a8&code="
    domain = 'https://graph.facebook.com'
    uri = '/oauth/access_token'
    query = 'client_id=230574627021570&'
    query += 'redirect_uri='
    query += configatron.server_url
    query += '/auth/facebook/callback&'
    query += 'client_secret=d27fb4a5d443f29cfdbddd79638c91a8&'
    query += 'code=' + code
    link = domain + uri + '?' + query

    response = HTTParty.get(URI.encode(link))

    data = response.body
    p "facebook response.body: #{data}"
    access_token = data.split("=")[1]
    p "facebook access_token: #{access_token}"

    user = get_user_for_token( access_token )
    if !user.nil?
      sign_in user
    end
  rescue => e
    logger.debug "ERROR FACEBOOK CALLBACK Message:   #{e.message}"
    logger.debug "ERROR FACEBOOK CALLBACK backtrace: #{e.backtrace}"
  end

  private

    def get_user_for_token(token)
      json_user = JSON.parse HTTParty.get('https://graph.facebook.com/me?access_token=' + URI.escape(token)).response.body
      p "facebook json_user: #{json_user}"

      user = User.find_by_fb_id( json_user['id'] )
      if !user.nil?
        user.fb_token = token
        user.save
        return user
      end
      
      user = User.find_by_email(json_user['email'])
      if !user.nil?
        user.fb_id = json_user['id']
        user.fb_token = token
        user.save
        return user
      end
      
      user = User.new
      user.update_from_fb_json(json_user, token)
      user.terms = true
      user.datenerhebung = true
      if user.save
        p "facebook: new user stored in db #{user.username}"
      else
        p "facebook: couldn't store new user in db."
      end
      User.new_user_email(user)
      return user
    end

end