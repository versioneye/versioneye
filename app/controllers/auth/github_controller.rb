class Auth::GithubController < ApplicationController

  before_filter :set_locale
  before_filter :enterprise_activated?

  def callback
    code      = params['code']
    token     = Github.token code
    hash_user = Github.user token

    if signed_in?
      update_user hash_user, token, true
      set_github_scope token
      redirect_to settings_connect_path
      return
    end

    user = user_for_github_id( hash_user )
    if user
      login user, nil, token
      update_user hash_user, token, true
      return
    end

    email = primary_email token
    if email.to_s.empty?
      flash.now[:error] = 'We are not able to fetch your email from the GitHub API. Please complete your email address.'
      init_variables_for_new_page user, email
      render auth_github_new_path and return
    end

    user = User.find_by_email( email )
    if user
      login user
      return
    end

    user_email = UserEmail.find_by_email( email )
    if user_email # than ask for another email
      flash.now[:error] = "The email address is already taken."
      prepare_new_page user, token
      render auth_github_new_path
      return
    end

    user = new_user( token, email, true )
    if user.save
      login user
    else
      flash.now[:error] = 'An error occured during saving your data.'
      init_variables_for_new_page user, email
      render auth_github_new_path
    end
  end


  def create
    @email = params[:email]
    @terms = params[:terms]
    @promo = params[:promo_code]

    token = cookies.signed[:github_token]
    if token == nil || token.empty?
      flash.now[:error] = 'An error occured. Your GitHub token is not available anymore. Please contact the VersionEye team.'
      render auth_github_new_path and return
    end

    unless @terms.eql?('1')
      flash.now[:error] = 'You have to accept the Conditions of Use AND the Data Aquisition.'
      init_variables_for_new_page nil, @email
      render auth_github_new_path and return
    end

    user = new_user( token, @email, @terms )
    user.create_verification
    if user.save
      user.send_verification_email
      login user, @promo
      return
    end

    flash.now[:error] = 'An error occured.'
    init_variables_for_new_page user, @email
    render auth_github_new_path
  end


  private


    def primary_email token
      emails = Github.emails token
      primary_email = emails.first[:email]
      emails.each do |em|
        if em[:primary] == true
          primary_email = em[:email]
        end
      end
      primary_email
    rescue => e
      Rails.logger.error e.message
      nil
    end


    def init_variables_for_new_page user = nil, email = nil
      @user = user
      @user = User.new({:email => email}) if user.nil?
      @email = email
      @terms = false
      @promo = cookies.signed[:promo_code]
    end


    def update_user(hash_user, token, repo_reset)
      user = current_user
      user.github_id = hash_user[:id]
      user.github_token = token

      update_scope user, token

      reset_repos(user) if repo_reset == true

      user.save
    end


    def reset_repos user
      # The next line is mandatory otherwise the private
      # repos don't get fetched immediately (reiz)
      user.github_repos.delete_all
      user.save
    end


    def update_scope user, token
      scopes = Github.oauth_scopes( token )
      if scopes && scopes.is_a?(Array)
        user.github_scope = scopes.join ','
      end
    rescue => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
    end


    def user_for_github_id(json_user)
      return nil if json_user.nil?
      return nil if json_user[:id].nil?
      user = User.find_by_github_id( json_user[:id].to_s )
      return user if user
      nil
    end


    def new_user token, email, terms
      json_user = Github.user token
      return nil if json_user.nil?

      user      = User.new
      user.update_from_github_json( json_user, token )
      user.email         = email
      user.terms         = terms
      user.datenerhebung = terms
      user
    end


    def prepare_new_page user, token
      cookies.permanent.signed[:github_token] = token
      email = primary_email token
      init_variables_for_new_page user, email
    end


    def login user, promo = nil, token = nil
      sign_in( user )
      update_scope(user, user.github_token)
      user.github_token = token if token
      user.save
      check_promo_code promo, user
      cookies.delete(:promo_code)
      cookies.delete(:github_token)
      rpath = user_projects_github_repositories_path
      rpath = user_projects_path if user.projects && !user.projects.empty?
      redirect_back_or( rpath )
    end


    def set_github_scope token
      scopes = Github.oauth_scopes( token )
      if scopes.is_a? Array
        set_gh_scope scopes.join ','
        return nil
      end

      if scopes.is_a?(String) && scopes.to_s.empty?
        return nil
      end

      set_gh_scope scopes
    end

end
