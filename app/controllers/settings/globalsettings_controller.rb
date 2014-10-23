class Settings::GlobalsettingsController < ApplicationController

  before_filter :authenticate_admin

  def index
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['server_url'] = Settings.instance.server_url
    @globalsetting['server_host'] = Settings.instance.server_host
    @globalsetting['server_port'] = Settings.instance.server_port
    @globalsetting['default_project_period'] = Settings.instance.default_project_period
    @globalsetting['default_project_public'] = Settings.instance.default_project_public
    @globalsetting['show_signup_form'] = Settings.instance.show_signup_form
    @globalsetting['show_login_form'] = Settings.instance.show_login_form
  end

  def index_github
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['github_base_url'] = Settings.instance.github_base_url
    @globalsetting['github_api_url'] = Settings.instance.github_api_url
    @globalsetting['github_client_id'] = Settings.instance.github_client_id
    @globalsetting['github_client_secret'] = Settings.instance.github_client_secret
  end

  def index_bitbucket
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['bitbucket_base_url'] = Settings.instance.bitbucket_base_url
    @globalsetting['bitbucket_token'] = Settings.instance.bitbucket_token
    @globalsetting['bitbucket_secret'] = Settings.instance.bitbucket_secret
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

  def index_mvnrepos
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['mvn_repo_1']          = Settings.instance.mvn_repo_1
    @globalsetting['mvn_repo_1_type']     = Settings.instance.mvn_repo_1_type
    @globalsetting['mvn_repo_1_user']     = Settings.instance.mvn_repo_1_user
    @globalsetting['mvn_repo_1_password'] = Settings.instance.mvn_repo_1_password
    @globalsetting['mvn_repo_1_schedule'] = Settings.instance.mvn_repo_1_schedule
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

  def index_scheduler
    env = Settings.instance.environment
    @globalsetting = {}
    @globalsetting['schedule_follow_notifications']         = GlobalSetting.get env, 'schedule_follow_notifications'
    @globalsetting['schedule_project_notification_daily']   = GlobalSetting.get env, 'schedule_project_notification_daily'
    @globalsetting['schedule_project_notification_weekly']  = GlobalSetting.get env, 'schedule_project_notification_weekly'
    @globalsetting['schedule_project_notification_monthly'] = GlobalSetting.get env, 'schedule_project_notification_monthly'
    @globalsetting['sync_db']                               = GlobalSetting.get env, 'sync_db'

    @globalsetting['schedule_follow_notifications']         = '15 8 * * *'  if @globalsetting['schedule_follow_notifications'].to_s.empty?
    @globalsetting['schedule_project_notification_daily']   = '15 9 * * *'  if @globalsetting['schedule_project_notification_daily'].to_s.empty?
    @globalsetting['schedule_project_notification_weekly']  = '15 11 * * 2' if @globalsetting['schedule_project_notification_weekly'].to_s.empty?
    @globalsetting['schedule_project_notification_monthly'] = '1 11 1 * *'  if @globalsetting['schedule_project_notification_monthly'].to_s.empty?
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

    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "Global Server Settings changed successfully"
    redirect_to settings_globalsettings_path
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


  def update_bitbucket
    env = Settings.instance.environment
    GlobalSetting.set env, 'bitbucket_base_url', params[:bitbucket_base_url]
    GlobalSetting.set env, 'bitbucket_token'   , params[:bitbucket_token]
    GlobalSetting.set env, 'bitbucket_secret'  , params[:bitbucket_secret]
    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "GitHub Settings changed successfully"
    redirect_to settings_bitbucketsettings_path
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
    GlobalSetting.set( env, 'mvn_repo_1_schedule', params[:mvn_repo_1_schedule] )

    Settings.instance.reload_from_db GlobalSetting.new

    flash[:success] = "Maven Repository Settings changed successfully!"
    redirect_to settings_mvnrepos_path
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


  def update_scheduler
    env = Settings.instance.environment

    GlobalSetting.set( env, 'schedule_follow_notifications',         params[:schedule_follow_notifications] )
    GlobalSetting.set( env, 'schedule_project_notification_daily',   params[:schedule_project_notification_daily] )
    GlobalSetting.set( env, 'schedule_project_notification_weekly',  params[:schedule_project_notification_weekly] )
    GlobalSetting.set( env, 'schedule_project_notification_monthly', params[:schedule_project_notification_monthly] )
    GlobalSetting.set( env, 'sync_db', params[:sync_db] )

    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "Scheduler updated successfully. Please restart the veye/tasks Docker container to activate the changes."
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
