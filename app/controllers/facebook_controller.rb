class FacebookController < ApplicationController

  layout "plain"

  def callback
    code = params['code']

    if code.nil? || code.empty?
      redirect_to "/signup"
      return
    end

    link = get_link(code)

    p "link: #{link}"
    response = HTTParty.get(URI.encode(link))

    data = response.body
    access_token = data.split("=")[1]

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
      p "json_user: #{json_user}"

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

    def get_link(code)
      domain = 'https://graph.facebook.com'
      uri = '/oauth/access_token'
      query = 'client_id='
      query += Settings.facebook_client_id.to_s
      query += '&redirect_uri='
      query += Settings.server_url
      query += '/auth/facebook/callback&'
      query += 'client_secret='
      query += Settings.facebook_client_secret
      query += '&code=' + code
      link = domain + uri + '?' + query
      link
    end

end