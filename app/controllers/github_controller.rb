class GithubController < ApplicationController

  before_filter :set_locale

  def callback
    code = params['code']

    @user = User.new
    domain = 'https://github.com/'
    uri = 'login/oauth/access_token'
    query = 'client_id=50fb47103b8a3f03b2cd&'
    query += 'client_secret=621051dd2033682449f62a5452a0e54b6c432907&'
    query += 'code=' + code
    link = "#{domain}#{uri}?#{query}"

    doc = Nokogiri::HTML( open( URI.encode(link) ) )
    p_element = doc.xpath('//body/p')
    p_string = p_element.text
    pips = p_string.split("&")
    token = pips[0].split("=")[1]
    type  = pips[1].split("=")[1]
    
    json_user = get_json_user( token )
    user = get_user_for_token( json_user, token )
    if !user.nil?
      sign_in user
      redirect_back_or( "/users/#{user.username}/favoritepackages" )
      return 
    else
      cookies.permanent.signed[:github_token] = token
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
      p "ERROR --- The E-Mail address is already taken. Please choose another E-Mail."
      flash.now[:error] = "The E-Mail address is already taken. Please choose another E-Mail."
      render 'new'
    elsif @terms != 1 || @datenerhebung != 1
      p "ERROR --- You have to accept the Conditions of Use AND the Data Aquisition."
      flash.now[:error] = "You have to accept the Conditions of Use AND the Data Aquisition."
      render 'new'
    else    
      token = cookies.signed[:github_token]
      p "token: #{token}"
      json_user = get_json_user( token )
      user = User.new
      user.update_from_github_json(json_user, token)
      user.terms = true
      user.datenerhebung = true
      user.create_verification
      if user.save
        user.send_verification_email
        User.new_user_email(user)
        cookies.delete(:github_token)
        render 'create'
      else 
        p "ERROR ---- An error occured. Please contact the VersionEye Team."
        flash.now[:error] = "An error occured. Please contact the VersionEye Team."
        render 'new'
      end
    end
  end

  private

    def get_json_user( token )
      json_user = JSON.parse HTTParty.get('https://api.github.com/user?access_token=' + URI.escape(token) ).response.body
    end

    def get_user_for_token(json_user, token)
      user = User.find_by_github_id( json_user['id'] )
      if !user.nil?
        user.github_token = token
        user.save
        return user
      end      
      user = User.find_by_email( json_user['email'] )
      if !user.nil?
        user.github_id = json_user['id']
        user.github_token = token
        user.save
        return user
      end
      return nil
    end

end