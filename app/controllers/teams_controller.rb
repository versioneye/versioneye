class TeamsController < ApplicationController

  before_filter :authenticate, :load_orga, :auth_org_member
  before_filter :auth_org_owner, :only => [:create, :add, :remove, :delete]

  def index
    @teams = Team.by_organisation( @organisation )
  end

  def create
    @team = Team.find_or_create_by(:organisation_id => @organisation.ids, :name => params[:teams][:name])
    redirect_to organisation_team_path(@organisation, @team)
  end

  def show
    @team = Team.where(:id => params[:id], :organisation_id => @organisation.ids).first
  end

  def add
    @team = Team.where(:id => params[:id], :organisation_id => @organisation.ids).first
    user = User.find_by_username params[:username]
    @team.add_member user
    redirect_to organisation_team_path(@organisation, @team)
  end

  def remove
    @team = Team.where(:id => params[:id], :organisation_id => @organisation.ids).first
    user = User.find_by_username params[:username]
    if @team.name.eql?( Team::A_OWNERS ) && @team.members.count == 1
      flash[:error] = "There must be at least 1 users on the #{Team::A_OWNERS} team!"
    else
      @team.remove_member user
    end
    redirect_to organisation_team_path(@organisation, @team)
  end

  def delete
    @team = Team.where(:id => params[:id], :organisation_id => @organisation.ids).first
    if @team.name.eql?( Team::A_OWNERS )
      flash[:error] = "The #{Team::A_OWNERS} team can not be deleted!"
    else
      TeamService.delete @team
    end
    redirect_to organisation_teams_path(@organisation)
  end


  private


    def load_orga
      @organisation = Organisation.where(:name => params[:organisation_name]).first
    end

    def auth_org_member
      return true if OrganisationService.member?(@organisation, current_user)
      false
    end

    def auth_org_owner
      return true if OrganisationService.owner?(@organisation, current_user)
      flash[:error] = "You are not in the Owners team. You don't have the permission for this operation."
      false
    end

end
