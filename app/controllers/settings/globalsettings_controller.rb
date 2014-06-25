class Settings::GlobalsettingsController < ApplicationController

  before_filter :authenticate_admin

  def index
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['server_url'] = Settings.instance.server_url
    @globalsetting['server_host'] = Settings.instance.server_host
    @globalsetting['server_port'] = Settings.instance.server_port
  end

  def index_github
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['github_base_url'] = Settings.instance.github_base_url
    @globalsetting['github_api_url'] = Settings.instance.github_api_url
    @globalsetting['github_client_id'] = Settings.instance.github_client_id
    @globalsetting['github_client_secret'] = Settings.instance.github_client_secret
  end

  def index_nexus
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}
    @globalsetting['nexus_url'] = Settings.instance.nexus_url
  end

  def index_cocoapods
    Settings.instance.reload_from_db GlobalSetting.new
    @globalsetting = {}

    @globalsetting['cocoapods_spec_git'] = Settings.instance.cocoapods_spec_git
    @globalsetting['cocoapods_spec_url'] = Settings.instance.cocoapods_spec_url

    @globalsetting['cocoapods_spec_git_2'] = ''
    @globalsetting['cocoapods_spec_url_2'] = ''

    begin
      @globalsetting['cocoapods_spec_git_2'] = Settings.instance.cocoapods_spec_git_2
      @globalsetting['cocoapods_spec_url_2'] = Settings.instance.cocoapods_spec_url_2
    rescue => e
      p "index_cocoapods: #{e.message}" # No big deal. It might be that there is no 2nd cocoapods repo!
    end
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


  def update_nexus
    env = Settings.instance.environment
    GlobalSetting.set( env, 'nexus_url', params[:nexus_url] )
    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "Nexus Settings changed successfully"
    redirect_to settings_nexussettings_path
  end


  def update_cocoapods
    env = Settings.instance.environment

    GlobalSetting.set( env, 'cocoapods_spec_git', params[:cocoapods_spec_git] )
    GlobalSetting.set( env, 'cocoapods_spec_url', params[:cocoapods_spec_url] )

    GlobalSetting.set( env, 'cocoapods_spec_git_2', params[:cocoapods_spec_git_2] )
    GlobalSetting.set( env, 'cocoapods_spec_url_2', params[:cocoapods_spec_url_2] )

    Settings.instance.reload_from_db GlobalSetting.new
    flash[:success] = "CocoaPods Specs changed successfully"
    redirect_to settings_cocoapods_path
  end

end
