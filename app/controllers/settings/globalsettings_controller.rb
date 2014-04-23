class Settings::GlobalsettingsController < ApplicationController

  before_filter :authenticate_admin

  def index
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

  private

    def update_settings globalsetting
      Settings.instance.server_url  = globalsetting.server_url
      Settings.instance.server_host = globalsetting.server_host
      Settings.instance.server_port = globalsetting.server_port
    end

    def update_routes globalsetting
      Rails.application.routes.default_url_options[:host] = globalsetting.server_host
      Rails.application.routes.default_url_options[:port] = globalsetting.server_port
    end

end
