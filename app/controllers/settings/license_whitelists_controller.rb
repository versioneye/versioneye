class Settings::LicenseWhitelistsController < ApplicationController

  before_filter :authenticate

  def index
    @whitelists = LicenseWhitelist.by_user current_user
  end

  def show
    @license_whitelist = LicenseWhitelist.fetch_by current_user, params[:name]
  end

  def create
    whitelist = LicenseWhitelist.new
    whitelist.update_from params[:license_whitelist]
    whitelist.user = current_user
    if whitelist.save
      flash[:success] = "Whitelist #{params[:name]} was created successfully."
      redirect_to :back
    else
      flash[:error] = "An error occured. We couldn't save the new Whitelist."
      redirect_to :back
    end
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We couldn't save the new Whitelist."
    redirect_to :back
  end

  def destroy
    license_whitelist = LicenseWhitelist.fetch_by current_user, params[:name]
    license_whitelist.destroy
    flash[:success] = "Whitelist deleted successfully."
    redirect_to :back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We couldn't delete the Whitelist."
    redirect_to :back
  end

end
