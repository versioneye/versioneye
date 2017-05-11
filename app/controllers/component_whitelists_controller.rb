class ComponentWhitelistsController < ApplicationController

  before_action :authenticate
  before_action :load_orga
  before_action :auth_org_member
  before_action :auth_org_owner, :except => [:index, :show]

  def index
    @whitelists = ComponentWhitelistService.index @organisation
  end

  def show
    @component_whitelist = ComponentWhitelistService.fetch_by @organisation, params[:id]
  end

  def create
    list_name = params[:component_whitelist][:name]
    resp = ComponentWhitelistService.create @organisation, list_name
    if resp
      flash[:success] = "Whitelist #{list_name} was created successfully."
      redirect_back
    else
      flash[:error] = "An error occured. We couldn't save the new whitelist."
      redirect_back
    end
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We couldn't save the new Whitelist."
    redirect_back
  end

  def destroy
    component_whitelist = ComponentWhitelist.fetch_by @organisation, params[:id]
    component_whitelist.destroy
    flash[:success] = "Component whitelist deleted successfully."
    redirect_back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We couldn't delete the component whitelist."
    redirect_back
  end


  def add
    cwl_name = params[:id]      # name of the component whitelist
    cwl_key  = params[:cwl_key] # element key on the component whitelist
    resp = ComponentWhitelistService.add @organisation, cwl_name, cwl_key
    p "resp: #{resp}"
    if resp
      cwl = ComponentWhitelistService.fetch_by @organisation, cwl_name
      Auditlog.add current_user, 'ComponentWhitelist', cwl.ids, "Added \"#{cwl_key}\" to \"#{cwl_name}\""
      flash[:success] = "Component added successfully."
    else
      flash[:error] = "An error occured. Not able to add the component to the list."
    end
    redirect_back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We could not add the component. (#{e.message})"
    redirect_back
  end


  def default
    ComponentWhitelistService.default @organisation, params[:id]

    cwl = ComponentWhitelistService.fetch_by @organisation, params[:id]
    Auditlog.add current_user, 'ComponentWhitelist', cwl.id.to_s, "Marked \"#{params[:id]}\" to default list."
    flash[:success] = "License Whitelist updated successfully."

    redirect_back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We could not update the status."
    redirect_back
  end

  def remove
    resp = ComponentWhitelistService.remove @organisation, params[:id], params[:cwl_key]
    if resp
      cwl = ComponentWhitelistService.fetch_by @organisation, params[:id]
      Auditlog.add current_user, 'ComponentWhitelist', cwl.id.to_s, "Removed \"#{params[:cwl_key]}\" from \"#{params[:id]}\""
      flash[:success] = "Component removed successfully."
    else
      flash[:error] = "An error occured. Not able to remove the component from the list."
    end
    redirect_back
  rescue => e
    logger.error e.message
    flash[:error] = "An error occured. We could not remove the component from the list."
    redirect_back
  end

end
