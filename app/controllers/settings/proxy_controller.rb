class Settings::ProxyController < ApplicationController

  before_filter :authenticate

  def index
    env = Settings.instance.environment
    @globalsetting = {}
    @globalsetting['proxy_addr'] = GlobalSetting.get env, 'proxy_addr'
    @globalsetting['proxy_port'] = GlobalSetting.get env, 'proxy_port'
    @globalsetting['proxy_user'] = GlobalSetting.get env, 'proxy_user'
    @globalsetting['proxy_pass'] = GlobalSetting.get env, 'proxy_pass'
  end

  def update
    proxy_addr = params[:proxy_addr]
    proxy_port = params[:proxy_port]
    proxy_user = params[:proxy_user]
    proxy_pass = params[:proxy_pass]

    env = Settings.instance.environment
    GlobalSetting.set env, 'proxy_addr', proxy_addr
    GlobalSetting.set env, 'proxy_port', proxy_port
    GlobalSetting.set env, 'proxy_user', proxy_user
    GlobalSetting.set env, 'proxy_pass', proxy_pass

    flash[:success] = "Proxy Settings changed successfully"
    redirect_to settings_proxy_path()
  end

end
