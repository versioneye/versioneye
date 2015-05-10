class Settings::LicenseWhitelistsController < ApplicationController

  before_filter :authenticate_lwl

  def index
    @whitelists = LicenseWhitelistService.index current_user
  end

  def show
    @license_whitelist = LicenseWhitelistService.fetch_by current_user, params[:name]
    @license_whitelist.license_elements.sort_by! &:name_substitute
  end

  def create
    list_name = params[:license_whitelist][:name]
    resp = LicenseWhitelistService.create current_user, list_name
    if resp
      flash[:success] = "Whitelist #{list_name} was created successfully."
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
    resp = LicenseWhitelistService.add current_user, params[:list], params[:license_name]
    if resp
      lwl = LicenseWhitelistService.fetch_by current_user, params[:list]
      le  = LicenseElement.new({:name => params[:license_name]})
      Auditlog.add current_user, 'LicenseWhitelist', lwl.id.to_s, "Added \"#{le.name_substitute}\" to \"#{params[:list]}\""
      flash[:success] = "License added successfully."
    else
      flash[:error] = "An error occured. Not able to add the license to the list."
    end
    redirect_to :back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We couldn't delete the Whitelist."
    redirect_to :back
  end

  def default 
    LicenseWhitelistService.default current_user, params[:list]
    
    lwl = LicenseWhitelistService.fetch_by current_user, params[:list]
    Auditlog.add current_user, 'LicenseWhitelist', lwl.id.to_s, "Marked \"#{params[:list]}\" to default list."
    flash[:success] = "License Whitelist updated successfully."
    
    redirect_to :back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We couldn't delete the Whitelist."
    redirect_to :back  
  end

  def remove
    resp = LicenseWhitelistService.remove current_user, params[:list], params[:name]
    if resp
      lwl = LicenseWhitelistService.fetch_by current_user, params[:list]
      Auditlog.add current_user, 'LicenseWhitelist', lwl.id.to_s, "Removed \"#{params[:name]}\" from \"#{params[:list]}\""
      flash[:success] = "License removed successfully."
    else
      flash[:error] = "An error occured. Not able to remove the license from the list."
    end
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
