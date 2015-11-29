class TeamsController < ApplicationController

  before_filter :authenticate, :load_orga, :auth_org_member
  before_filter :auth_org_owner, :only => [:create, :add, :delete]

  def index
    @teams = Team.by_organisation( @organisation )
  end

  def create
    if OrganisationService.owner?(@organisation, current_user)
      @team = Team.find_or_create_by(:organisation_id => @organisation.ids, :name => params[:teams][:name])
      redirect_to organisation_team_path(@organisation, @team)
    else
      flash[:error] = "You have no permission to create a Team. Only the owners of the organisation are allowed to do that."
      redirect_to organisation_teams_path(@organisation)
    end
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
      flash[:error] = "There must be at least 1 user at the #{Team::A_OWNERS} team!"
    elsif OrganisationService.owner?(@organisation, current_user) || user.username.eql?(current_user.username)
      @team.remove_member user
    else
      flash[:error] = "You have not permission to remove this user from the Team. Only the owners of the organisation are allowed to do that."
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


end
