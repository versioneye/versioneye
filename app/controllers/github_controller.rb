class GithubController < ApplicationController

  before_filter :set_locale

  def callback
    code = params['code']

    if code.nil? || code.empty?
      redirect_to "/signup"
      return
    end

    token = get_token( code )
    json_user = Github.user token 
    
    if signed_in?
      user = current_user
      user.github_id = json_user['id']
      user.github_token = token
      user.github_scope = Github.oauth_scopes( token )
      user.save
      redirect_to settings_connect_path
      return
    end
    
    user = get_user_for_token( json_user, token )
    if !user.nil?
      sign_in user
      redirect_back_or( "/user/projects" )
      return 
    else
      cookies.permanent.signed[:github_token] = token
      @user = User.new
      render "new"
    end
  end
  
  def new
    @email = ""
    @terms = false
  end
  
  def create    
    @email = params[:email]
    @terms = params[:terms]

    if !User.email_valid?(@email)
      flash.now[:error] = "The E-Mail address is already taken. Please choose another E-Mail."
      render 'new'
    elsif !@terms.eql?("1")
      flash.now[:error] = "You have to accept the Conditions of Use AND the Data Aquisition."
      render 'new'
    else    
      token = cookies.signed[:github_token]
      if token == nil || token.empty?
        flash.now[:error] = "An error occured. Your GitHub token is not anymore available. Please try again later."
        render 'new'
        return
      end
      json_user = Gtihub.user( token )
      user = User.new
      scopes = Github.oauth_scopes( token )
      user.update_from_github_json(json_user, token, scopes)
      user.email = @email
      user.terms = true
      user.datenerhebung = true
      user.create_verification
      if user.save
        user.send_verification_email
        User.new_user_email(user)
        cookies.delete(:github_token)
        sign_in user
        render 'create'
      else 
        flash.now[:error] = "An error occured. Please contact the VersionEye Team."
        render 'new'
      end
    end
  end
  
  def get_token( code )
    domain = 'https://github.com/'
    uri = 'login/oauth/access_token'
    query = 'client_id='
    query += Settings.github_client_id
    query += '&client_secret='
    query += Settings.github_client_secret
    query += '&code=' + code
    link = "#{domain}#{uri}?#{query}"

    doc = Nokogiri::HTML( open( URI.encode(link) ) )
    p_element = doc.xpath('//body/p')
    p_string = p_element.text
    pips = p_string.split("&")
    token = pips[0].split("=")[1]
    token
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