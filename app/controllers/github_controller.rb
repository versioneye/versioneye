class GithubController < ApplicationController

  layout "plain"

  def callback
    code = params['code']

    domain = 'https://github.com/'
    uri = 'login/oauth/access_token'
    query = 'client_id=50fb47103b8a3f03b2cd&'
    query += 'client_secret=621051dd2033682449f62a5452a0e54b6c432907&'
    query += 'code=' + code
    link = "#{domain}#{uri}?#{query}"

    token_type = ""
    access_token = ""
    doc = Nokogiri::HTML( open( URI.encode(link) ) )
    doc.xpath('//OAuth/token_type').each do |t_type|
      token_type = t_type
      break
    end
    doc.xpath('//OAuth/access_token').each do |access|
      access_token = access
      break
    end
    p "token_type: #{token_type} - access_token: #{access_token}"
    @result = "token_type: #{token_type} - access_token: #{access_token}"
    
    # user = get_user_for_token( access_token )
    #     if !user.nil?
    #       sign_in user
    #     end
  end

  private

    def get_user_for_token(token)
      json_user = JSON.parse HTTParty.get('https://graph.facebook.com/me?access_token=' + URI.escape(token)).response.body
      
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
      user.save
      return user
    end

end