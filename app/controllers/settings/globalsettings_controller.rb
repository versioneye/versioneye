class Settings::GlobalsettingsController < ApplicationController

  before_filter :authenticate_admin

  def index
    @globalsetting = GlobalSetting.default
  end

  def index_github
    @globalsetting = GlobalSetting.default
  end

  def index_nexus
    @globalsetting = GlobalSetting.default
  end

  def update
    @globalsetting = GlobalSetting.default
    @globalsetting.server_url  = params[:server_url]
    @globalsetting.server_host = params[:server_host]
    @globalsetting.server_port = params[:server_port]
    if @globalsetting.save
      update_routes   @globalsetting
      update_settings @globalsetting
      flash[:success] = "Global Server Settings changed successfully"
    else
      flash[:error] = "Something went wrong - #{es.errors.full_messages.to_sentence}"
    end
    redirect_to settings_globalsettings_path
  end

  def update_github
    @globalsetting = GlobalSetting.default
    @globalsetting.github_base_url       = params[:github_base_url]
    @globalsetting.github_api_url       = params[:github_api_url]
    @globalsetting.github_client_id     = params[:github_client_id]
    @globalsetting.github_client_secret = params[:github_client_secret]
    if @globalsetting.save
      update_github_settings @globalsetting
      flash[:success] = "GitHub Settings changed successfully"
    else
      flash[:error] = "Something went wrong - #{es.errors.full_messages.to_sentence}"
    end
    redirect_to settings_githubsettings_path
  end

  def update_nexus
    @globalsetting = GlobalSetting.default
    @globalsetting.nexus_url = params[:nexus_url]
    if @globalsetting.save
      update_nexus_settings @globalsetting
      flash[:success] = "Nexus Settings changed successfully"
    else
      flash[:error] = "Something went wrong - #{es.errors.full_messages.to_sentence}"
    end
    redirect_to settings_nexussettings_path
  end

  private

    def update_settings globalsetting
      Settings.instance.server_url  = globalsetting.server_url
      Settings.instance.server_host = globalsetting.server_host
      Settings.instance.server_port = globalsetting.server_port
    end

    def update_github_settings globalsetting
      Settings.instance.github_base_url      = globalsetting.github_base_url
      Settings.instance.github_api_url       = globalsetting.github_api_url
      Settings.instance.github_client_id     = globalsetting.github_client_id
      Settings.instance.github_client_secret = globalsetting.github_client_secret
    end

    def update_nexus_settings globalsetting
      Settings.instance.nexus_url = globalsetting.nexus_url
    end

    def update_routes globalsetting
      Rails.application.routes.default_url_options[:host] = globalsetting.server_host
      Rails.application.routes.default_url_options[:port] = globalsetting.server_port
    end

end
