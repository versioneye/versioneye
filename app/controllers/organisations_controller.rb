class OrganisationsController < ApplicationController

  before_filter :authenticate
  before_filter :auth_org_member, :only => [:projects, :show]
  before_filter :auth_org_owner,  :only => [:update, :delete]

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
    # see before_filter auth_org_member
  end

  def index
    @organisations = OrganisationService.index current_user
    redirect_to new_organisation_path if @organisations.empty?
  end

  def projects
    @projects = @organisation.projects
  end


  private


    def auth_org_member
      @organisation = Organisation.where(:name => params[:name]).first
      return true if OrganisationService.member?(@organisation, current_user)
      flash[:error] = "You are not a member of this organisation. You don't have the permission for this operation."
      redirect_to organisations_path
      return false
    end


    def auth_org_owner
      @organisation = Organisation.where(:name => params[:name]).first
      return true if OrganisationService.owner?(@organisation, current_user)
      flash[:error] = "You are not in the Owners team. You don't have the permission for this operation."
      redirect_to organisations_path
      return false
    end

end
