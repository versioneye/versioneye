class GithubController < ApplicationController

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
    p_string = ""
    doc = Nokogiri::HTML( open( URI.encode(link) ) )
    doc.xpath('//body/p').each do |val|
      p_string = val
      break
    end
    pps = p_string.split("&amp;")
    token = pps[0].split("=")[1]
    type  = pps[1].split("=")[1]
    
    p "token_type: #{type} - access_token: #{token}"
    @result = "token_type: #{type} - access_token: #{token} - doc: #{doc}"
    
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