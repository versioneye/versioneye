class LicenseWhitelistsController < ApplicationController

  before_action :authenticate
  before_action :load_orga
  before_action :auth_org_member
  before_action :auth_org_owner, :except => [:index, :show]

  def index
    @whitelists = LicenseWhitelistService.index @organisation
  end

  def show
    @license_whitelist = LicenseWhitelistService.fetch_by @organisation, params[:id]
    @license_whitelist.license_elements.sort_by! &:name_substitute
  end

  def create
    list_name = params[:license_whitelist][:name]
    resp = LicenseWhitelistService.create @organisation, list_name
    if resp
      flash[:success] = "Whitelist #{list_name} was created successfully."
      redirect_back
    else
      flash[:error] = "An error occured. We couldn't save the new Whitelist."
      redirect_back
    end
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We couldn't save the new Whitelist."
    redirect_back
  end

  def destroy
    license_whitelist = LicenseWhitelist.fetch_by @organisation, params[:id]
    license_whitelist.destroy
    flash[:success] = "Whitelist deleted successfully."
    redirect_back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We couldn't delete the Whitelist."
    redirect_back
  end

  def update_pessimistic
    license_whitelist = LicenseWhitelistService.fetch_by @organisation, params[:id]
    ps = params[:pessimistic]
    ignore_unknowns = params[:ignore_unknowns_on_pr]
    license_whitelist.pessimistic_mode = ps.to_s.eql?('true')
    license_whitelist.ignore_unknowns_on_pr = ignore_unknowns.to_s.eql?('true')
    if license_whitelist.save
      Auditlog.add current_user, 'LicenseWhitelist', license_whitelist.ids, "Update pessimistic_mode to \"#{license_whitelist.pessimistic_mode}\" "
      flash[:success] = "Pessimistic mode updated successfully."
    else
      flash[:error] = "An error occured. "
    end
    redirect_back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We could not update the status."
    redirect_back
  end

  def add
    resp = LicenseWhitelistService.add @organisation, params[:id], params[:license_name]
    if resp
      lwl = LicenseWhitelistService.fetch_by @organisation, params[:id]
      le  = LicenseElement.new({:name => params[:license_name]})
      Auditlog.add current_user, 'LicenseWhitelist', lwl.id.to_s, "Added \"#{le.name_substitute}\" to \"#{params[:id]}\""
      flash[:success] = "License added successfully."
    else
      flash[:error] = "An error occured. Not able to add the license to the list."
    end
    redirect_back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We could not add the license."
    redirect_back
  end

  def default
    LicenseWhitelistService.default @organisation, params[:id]

    lwl = LicenseWhitelistService.fetch_by @organisation, params[:id]
    Auditlog.add current_user, 'LicenseWhitelist', lwl.id.to_s, "Marked \"#{params[:id]}\" to default list."
    flash[:success] = "License Whitelist updated successfully."

    redirect_back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We could not update the status."
    redirect_back
  end

  def remove
    resp = LicenseWhitelistService.remove @organisation, params[:id], params[:name]
    if resp
      lwl = LicenseWhitelistService.fetch_by @organisation, params[:id]
      Auditlog.add current_user, 'LicenseWhitelist', lwl.id.to_s, "Removed \"#{params[:name]}\" from \"#{params[:id]}\""
      flash[:success] = "License removed successfully."
    else
      flash[:error] = "An error occured. Not able to remove the license from the list."
    end
    redirect_back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We could not remove the license from the list."
    redirect_back
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
