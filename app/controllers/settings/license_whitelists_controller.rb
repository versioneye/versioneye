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

  def add
    license_whitelist = LicenseWhitelist.fetch_by current_user, params[:list]
    license_whitelist.add_license_element params[:license_name]
    flash[:success] = "License added successfully."
    redirect_to :back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We couldn't delete the Whitelist."
    redirect_to :back
  end

  def remove
    license_whitelist = LicenseWhitelist.fetch_by current_user, params[:list]
    license_whitelist.remove_license_element params[:name]
    flash[:success] = "License removed successfully."
    redirect_to :back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We couldn't delete the Whitelist."
    redirect_to :back
  end

  def autocomplete
    term = params[:term]
    if term.nil?
      render json: [] and return
    end
    results = LicenseService.search(term)
    render json: format_autocompletion(results)
  end

  private

    def format_autocompletion(matched_licenses)
      results = []
      return results if matched_licenses.nil?

      matched_licenses.each_with_index do |spdx, i|
        results << {
          value: spdx[:fullname],
          license_name: spdx[:fullname],
          identifier: spdx[:identifier]
        }
        break if i > 12
      end

      results
    end

end
