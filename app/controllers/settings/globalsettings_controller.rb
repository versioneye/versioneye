class Settings::GlobalsettingsController < ApplicationController

  before_action :authenticate_admin

  def index
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['server_url'] = Settings.instance.server_url
    @globalsetting['server_host'] = Settings.instance.server_host
    @globalsetting['server_port'] = Settings.instance.server_port
    @globalsetting['timezone'] = Settings.instance.timezone
    @globalsetting['default_project_period'] = Settings.instance.default_project_period
    @globalsetting['default_project_public'] = Settings.instance.default_project_public
    @globalsetting['show_signup_form'] = Settings.instance.show_signup_form
    @globalsetting['show_login_form'] = Settings.instance.show_login_form
    @globalsetting['unique_ga']  = Settings.instance.projects_unique_ga
    @globalsetting['unique_gav']  = Settings.instance.projects_unique_gav
    @globalsetting['unique_scm'] = Settings.instance.projects_unique_scm
    @globalsetting['orga_creation_admin_only'] = Settings.instance.orga_creation_admin_only
    @globalsetting['disable_sync'] = Settings.instance.disable_sync
  end

  def update
    env = Settings.instance.environment
    GlobalSetting.set env, 'server_url' , params[:server_url]
    if GlobalSetting.set( env, 'server_host', params[:server_host] )
      Rails.application.routes.default_url_options[:host] = params[:server_host]
    end
    if GlobalSetting.set( env, 'server_port', params[:server_port] )
      Rails.application.routes.default_url_options[:port] = params[:server_port]
    end

    GlobalSetting.set( env, 'timezone', params[:timezone] )

    GlobalSetting.set( env, 'default_project_period', params[:default_project_period] )

    if params[:default_project_public] && params[:default_project_public].eql?("true")
      GlobalSetting.set( env, 'default_project_public', "true" )
    else
      GlobalSetting.set( env, 'default_project_public', "false" )
    end

    if params[:show_signup_form] && params[:show_signup_form].eql?("true")
      GlobalSetting.set( env, 'show_signup_form', "true" )
    else
      GlobalSetting.set( env, 'show_signup_form', "false" )
    end

    if params[:show_login_form] && params[:show_login_form].eql?("true")
      GlobalSetting.set( env, 'show_login_form', "true" )
    else
      GlobalSetting.set( env, 'show_login_form', "false" )
    end

    if params[:unique_ga] && params[:unique_ga].eql?("true")
      GlobalSetting.set( env, 'projects_unique_ga', "true" )
    else
      GlobalSetting.set( env, 'projects_unique_ga', "false" )
    end

    if params[:unique_gav] && params[:unique_gav].eql?("true")
      GlobalSetting.set( env, 'projects_unique_gav', "true" )
    else
      GlobalSetting.set( env, 'projects_unique_gav', "false" )
    end

    if params[:unique_scm] && params[:unique_scm].eql?("true")
      GlobalSetting.set( env, 'projects_unique_scm', "true" )
    else
      GlobalSetting.set( env, 'projects_unique_scm', "false" )
    end

    if params[:orga_creation_admin_only] && params[:orga_creation_admin_only].eql?("true")
      GlobalSetting.set( env, 'orga_creation_admin_only', "true" )
    else
      GlobalSetting.set( env, 'orga_creation_admin_only', "false" )
    end

    if params[:disable_sync] && params[:disable_sync].eql?("true")
      GlobalSetting.set( env, 'disable_sync', "true" )
    else
      GlobalSetting.set( env, 'disable_sync', "false" )
    end

    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "Global Server Settings changed successfully"
    redirect_to settings_globalsettings_path
  end


  def index_activation
    env = Settings.instance.environment
    @globalsetting = {}
    @globalsetting['api_key']         = GlobalSetting.get env, 'api_key'
    @globalsetting['api_url']         = GlobalSetting.get env, 'api_url'
    if @globalsetting['api_url'].to_s.empty?
      @globalsetting['api_url'] = 'https://www.versioneye.com/api'
    end
    @globalsetting['e_projects']      = GlobalSetting.get env, 'e_projects'
    @globalsetting['rate_limit']      = GlobalSetting.get env, 'E_RATE_LIMIT'
    @globalsetting['comp_limit']      = GlobalSetting.get env, 'E_COMP_LIMIT'
    @globalsetting['activation_date'] = GlobalSetting.get env, 'activation_date'
  end

  def update_activation
    env = Settings.instance.environment
    GlobalSetting.set env, 'api_url', params[:api_url]
    resp = EnterpriseService.activate!(params[:api_key])
    if resp == true
      flash[:success] = "API Key validated successfully!"
    else
      flash[:error] = "The API Key couldn't be validated. Please ensure that the VersionEye Enterprise instance is connected to the internet."
    end
    @globalsetting = {}
    @globalsetting['api_key']         = GlobalSetting.get env, 'api_key'
    @globalsetting['api_url']         = GlobalSetting.get env, 'api_url'
    @globalsetting['activation_date'] = GlobalSetting.get env, 'activation_date'
    Settings.instance.reload_from_db GlobalSetting.new
    redirect_to settings_activation_path
  end


  def index_github
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['github_base_url'] = Settings.instance.github_base_url
    @globalsetting['github_api_url'] = Settings.instance.github_api_url
    @globalsetting['github_client_id'] = Settings.instance.github_client_id
    @globalsetting['github_client_secret'] = Settings.instance.github_client_secret
  end

  def update_github
    env = Settings.instance.environment
    GlobalSetting.set env, 'github_base_url'     , params[:github_base_url]
    GlobalSetting.set env, 'github_api_url'      , params[:github_api_url]
    GlobalSetting.set env, 'github_client_id'    , params[:github_client_id]
    GlobalSetting.set env, 'github_client_secret', params[:github_client_secret]
    Settings.instance.reload_from_db GlobalSetting.new
    Octokit.configure do |c|
      c.api_endpoint = Settings.instance.github_api_url
      c.web_endpoint = Settings.instance.github_base_url
    end
    flash[:success] = "GitHub Settings changed successfully"
    redirect_to settings_githubsettings_path
  end


  def index_bitbucket
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['bitbucket_base_url'] = Settings.instance.bitbucket_base_url
    @globalsetting['bitbucket_token'] = Settings.instance.bitbucket_token
    @globalsetting['bitbucket_secret'] = Settings.instance.bitbucket_secret
  end

  def update_bitbucket
    env = Settings.instance.environment
    GlobalSetting.set env, 'bitbucket_base_url', params[:bitbucket_base_url]
    GlobalSetting.set env, 'bitbucket_token'   , params[:bitbucket_token]
    GlobalSetting.set env, 'bitbucket_secret'  , params[:bitbucket_secret]
    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "GitHub Settings changed successfully"
    redirect_to settings_bitbucketsettings_path
  end


  def index_stash
    env = Settings.instance.environment
    Settings.instance.reload_from_db GlobalSetting.new
    consumer_key = Settings.instance.stash_consumer_key
    if consumer_key.to_s.empty?
      consumer_key = create_random_value
      GlobalSetting.set env, 'stash_consumer_key' , consumer_key
    end
    @globalsetting = {}
    @globalsetting['stash_base_url'] = Settings.instance.stash_base_url
    @globalsetting['stash_consumer_key'] = consumer_key
    @globalsetting['stash_private_rsa'] = Settings.instance.stash_private_rsa
  end

  def update_stash
    consumer_key = params[:stash_consumer_key]
    if consumer_key.to_s.empty?
      consumer_key = create_random_value
    end
    env = Settings.instance.environment
    GlobalSetting.set env, 'stash_base_url'     , params[:stash_base_url]
    GlobalSetting.set env, 'stash_consumer_key' , consumer_key
    GlobalSetting.set env, 'stash_private_rsa'  , params[:stash_private_rsa]
    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "Stash Settings changed successfully"
    redirect_to settings_stashsettings_path
  end


  def index_ldap
    env = Settings.instance.environment
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['ldap_host']       = Settings.instance.ldap_host
    @globalsetting['ldap_port']       = Settings.instance.ldap_port
    @globalsetting['ldap_base']       = Settings.instance.ldap_base
    @globalsetting['ldap_filter']     = Settings.instance.ldap_filter
    @globalsetting['ldap_username_pattern'] = Settings.instance.ldap_username_pattern
    @globalsetting['ldap_email']      = Settings.instance.ldap_email
    @globalsetting['ldap_username']   = Settings.instance.ldap_username
    @globalsetting['ldap_auth']       = Settings.instance.ldap_auth
    @globalsetting['ldap_encryption'] = Settings.instance.ldap_encryption
    @globalsetting['ldap_active']     = Settings.instance.ldap_active
  end

  def update_ldap
    env = Settings.instance.environment
    GlobalSetting.set env, 'ldap_host'      , params[:ldap_host]
    GlobalSetting.set env, 'ldap_port'      , params[:ldap_port]
    GlobalSetting.set env, 'ldap_base'      , params[:ldap_base]
    GlobalSetting.set env, 'ldap_filter'    , params[:ldap_filter]
    GlobalSetting.set env, 'ldap_username_pattern', params[:ldap_username_pattern]
    GlobalSetting.set env, 'ldap_email'     , params[:ldap_email]
    GlobalSetting.set env, 'ldap_username'  , params[:ldap_username]
    GlobalSetting.set env, 'ldap_auth'      , params[:ldap_auth]
    GlobalSetting.set env, 'ldap_encryption', params[:ldap_encryption]
    GlobalSetting.set env, 'ldap_active'    , params[:ldap_active]
    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "LDAP Settings changed successfully"
    redirect_to settings_ldapsettings_path
  end

  def ldap_auth
    Settings.instance.reload_from_db GlobalSetting.new
    ldap_entity = LdapService.auth_by params[:ldap_login], params[:ldap_password]
    if ldap_entity && !ldap_entity.is_a?(String)
      username = ldap_entity.first[Settings.instance.ldap_username].first
      email    = ldap_entity.first[Settings.instance.ldap_email].first
      flash[:success] = "Successfully authenticated! Received username '#{username}' and email '#{email}'"
    elsif ldap_entity && ldap_entity.is_a?(String)
      flash[:error] = "An error occured! #{ldap_entity}"
    end
    redirect_to settings_ldapsettings_path
  rescue => e
    Rails.logger.error "Error in ldap_auth - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    flash[:error] = "An error occured. (#{e.message})"
    redirect_to settings_ldapsettings_path
  end


  def index_mvnrepos
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['mvn_repo_1']          = Settings.instance.mvn_repo_1
    @globalsetting['mvn_repo_1_type']     = Settings.instance.mvn_repo_1_type
    @globalsetting['mvn_repo_1_user']     = Settings.instance.mvn_repo_1_user
    @globalsetting['mvn_repo_1_password'] = Settings.instance.mvn_repo_1_password
    @globalsetting['mvn_repo_1_schedule'] = Settings.instance.mvn_repo_1_schedule
    @globalsetting['mvn_art_single_repo'] = Settings.instance.mvn_art_single_repo
    @globalsetting['mvn_art_ignore_keys'] = Settings.instance.mvn_art_ignore_keys
    @globalsetting['mvn_art_ignore_remote_repos']  = Settings.instance.mvn_art_ignore_remote_repos
    @globalsetting['mvn_art_ignore_local_repos']   = Settings.instance.mvn_art_ignore_local_repos
    @globalsetting['mvn_art_ignore_virtual_repos'] = Settings.instance.mvn_art_ignore_virtual_repos
  end

  def update_mvnrepos
    env = Settings.instance.environment
    url = params[:mvn_repo_1]
    if url.match(/\/\z/)
      url = url.gsub(/\/\z/, "")
    end
    GlobalSetting.set( env, 'mvn_repo_1', url )
    GlobalSetting.set( env, 'mvn_repo_1_type', params[:mvn_repo_1_type] )
    GlobalSetting.set( env, 'mvn_repo_1_user', params[:mvn_repo_1_user] )
    GlobalSetting.set( env, 'mvn_repo_1_password', params[:mvn_repo_1_password] )
    GlobalSetting.set( env, 'mvn_art_ignore_keys', params[:mvn_art_ignore_keys] )
    GlobalSetting.set( env, 'mvn_art_single_repo', params[:mvn_art_single_repo] )

    if params[:mvn_art_ignore_remote_repos].to_s.eql?('true')
      GlobalSetting.set( env, 'mvn_art_ignore_remote_repos', true )
    else
      GlobalSetting.set( env, 'mvn_art_ignore_remote_repos', false )
    end

    if params[:mvn_art_ignore_local_repos].to_s.eql?('true')
      GlobalSetting.set( env, 'mvn_art_ignore_local_repos', true )
    else
      GlobalSetting.set( env, 'mvn_art_ignore_local_repos', false )
    end

    if params[:mvn_art_ignore_virtual_repos].to_s.eql?('true')
      GlobalSetting.set( env, 'mvn_art_ignore_virtual_repos', true )
    else
      GlobalSetting.set( env, 'mvn_art_ignore_virtual_repos', false )
    end

    Settings.instance.reload_from_db GlobalSetting.new

    flash[:success] = "Maven Repository Settings changed successfully!"
    redirect_to settings_mvnrepos_path
  end


  def index_cocoapods
    env = Settings.instance.environment
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}

    @globalsetting['cocoapods_spec_git'] = Settings.instance.cocoapods_spec_git
    @globalsetting['cocoapods_spec_url'] = Settings.instance.cocoapods_spec_url

    @globalsetting['cocoapods_spec_git_2'] = ''
    @globalsetting['cocoapods_spec_url_2'] = ''

    @globalsetting['cocoapods_schedule'] = GlobalSetting.get(env, 'SCHEDULE_CRAWL_COCOAPODS')

    begin
      @globalsetting['cocoapods_spec_git_2'] = Settings.instance.cocoapods_spec_git_2
      @globalsetting['cocoapods_spec_url_2'] = Settings.instance.cocoapods_spec_url_2
    rescue => e
      p "index_cocoapods: #{e.message}" # No big deal. It might be that there is no 2nd cocoapods repo!
    end
  end

  def update_cocoapods
    env = Settings.instance.environment

    GlobalSetting.set( env, 'cocoapods_spec_git', params[:cocoapods_spec_git] )
    GlobalSetting.set( env, 'cocoapods_spec_url', params[:cocoapods_spec_url] )

    GlobalSetting.set( env, 'cocoapods_spec_git_2', params[:cocoapods_spec_git_2] )
    GlobalSetting.set( env, 'cocoapods_spec_url_2', params[:cocoapods_spec_url_2] )

    GlobalSetting.set(env, 'SCHEDULE_CRAWL_COCOAPODS', params[:cocoapods_schedule] )

    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "CocoaPods Specs changed successfully. Please restart the veye/crawlr Docker container to activate the changes."
    redirect_to settings_cocoapods_path
  end


  def index_satis
    env = Settings.instance.environment
    @globalsetting = {}
    @globalsetting['satis_base_url'] = GlobalSetting.get env, 'satis_base_url'
    @globalsetting['satis_schedule'] = GlobalSetting.get env, 'satis_schedule'
  end

  def update_satis
    env = Settings.instance.environment
    GlobalSetting.set env, 'satis_base_url'     , params[:satis_base_url]
    GlobalSetting.set env, 'satis_schedule'     , params[:satis_schedule]
    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "Satis Settings changed successfully"
    redirect_to settings_satis_path
  end


  def index_scheduler
    env = Settings.instance.environment
    @globalsetting = {}
    @globalsetting['schedule_follow_notifications'] = GlobalSetting.get env, 'schedule_follow_notifications'
    @globalsetting['schedule_team_notifications']   = GlobalSetting.get env, 'schedule_team_notifications'
    @globalsetting['sync_db']                       = GlobalSetting.get env, 'sync_db'

    @globalsetting['schedule_follow_notifications'] = '15 8 * * *'  if @globalsetting['schedule_follow_notifications'].to_s.empty?
    @globalsetting['schedule_team_notifications']   = '50 7 * * *'  if @globalsetting['schedule_team_notifications'].to_s.empty?
  end

  def update_scheduler
    env = Settings.instance.environment

    GlobalSetting.set( env, 'schedule_follow_notifications', params[:schedule_follow_notifications] )
    GlobalSetting.set( env, 'schedule_team_notifications',   params[:schedule_team_notifications] )
    GlobalSetting.set( env, 'sync_db', params[:sync_db] )

    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "Scheduler updated successfully. Please restart the versioneye/tasks Docker container to activate the changes."
    redirect_to settings_scheduler_path
  end

  private

    def create_random_value
      chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      value = ''
      12.times { value << chars[rand(chars.size)] }
      value
    end

end
