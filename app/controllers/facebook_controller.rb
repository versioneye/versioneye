class FacebookController < ApplicationController

  layout "plain"

  def callback
    code = params['code']

    if code.nil? || code.empty?
      redirect_to "/signup"
      return
    end

    link = get_link(code)
    response = HTTParty.get(URI.encode(link))
    data = response.body
    access_token = data.split("=")[1]

    if signed_in? 
      update_user_with_token(current_user, json_user, token)
      redirect_to settings_connect_path
      return 
    end

    user = get_user_for_token( access_token )
    if !user.nil?
      sign_in user
    end

    product_key = cookies[:prod_key]
    if product_key 
      response = ProductService.create_follower product_key, current_user
      if response.eql?("success")
        flash[:success] = "Congratulation. You are following now #{product_key} at VersionEye." 
        cookies.delete(:prod_key)
      end
    end
  rescue => e
    logger.error "ERROR FACEBOOK CALLBACK Message:   #{e.message}"
    logger.error "ERROR FACEBOOK CALLBACK backtrace: #{e.backtrace.first}"
  end

  private

    def get_user_for_token(token)
      json_user = JSON.parse HTTParty.get('https://graph.facebook.com/me?access_token=' + URI.escape(token)).response.body

      user = User.find_by_fb_id( json_user['id'] )
      if !user.nil? && !user.deleted
        user.fb_token = token
        user.save
        return user
      end
      
      user = User.find_by_email(json_user['email'])
      if !user.nil? && !user.deleted
        update_user_with_token(user, json_user, token)
        return user
      end
      
      user = User.new
      user.update_from_fb_json(json_user, token)
      user.terms = true
      user.datenerhebung = true
      user.save
      User.new_user_email( user )
      return user
    end

    def get_link(code)
      domain = 'https://graph.facebook.com'
      uri = '/oauth/access_token'
      query = 'client_id='
      query += Settings.facebook_client_id.to_s
      query += '&redirect_uri='
      query += Settings.server_url_https
      query += '/auth/facebook/callback&'
      query += 'client_secret='
      query += Settings.facebook_client_secret
      query += '&code=' + code
      link = domain + uri + '?' + query
      link
    end

    def update_user_with_token(user, json_user, token )
      user.fb_id = json_user['id']
      user.fb_token = token
      user.save
    end

end