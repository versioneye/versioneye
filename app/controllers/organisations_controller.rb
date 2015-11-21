class OrganisationsController < ApplicationController

  def new
    @organisation = Organisation.new
  end

  def create
    name = params[:organisation][:name]
    orga = OrganisationService.create_new current_user, name
    orga.company  = params[:organisation][:company]
    orga.location = params[:organisation][:location]
    orga.email    = params[:organisation][:email]
    orga.website  = params[:organisation][:website]
    orga.save
    redirect_to organisations_path
  rescue => e
    flash[:error] = e.message
    redirect_to :back
  end

  def update

  end

  def show

  end

  def index
    @organisations = OrganisationService.index current_user
    redirect_to new_organisation_path if @organisations.empty?
  end

end
