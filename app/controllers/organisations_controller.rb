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
    @organisation = Organisation.where(:name => params[:name]).first
    @organisation.name     = params[:organisation][:name]
    @organisation.company  = params[:organisation][:company]
    @organisation.location = params[:organisation][:location]
    @organisation.email    = params[:organisation][:email]
    @organisation.website  = params[:organisation][:website]
    @organisation.save
    flash[:success] = "Organisation saved successfully"
    redirect_to organisation_path(@organisation)
  rescue => e
    flash[:error] = e.message
    redirect_to :back
  end

  def show
    @organisation = Organisation.where(:name => params[:name]).first
  end

  def index
    @organisations = OrganisationService.index current_user
    redirect_to new_organisation_path if @organisations.empty?
  end

end
