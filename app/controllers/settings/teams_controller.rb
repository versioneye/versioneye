class Settings::TeamsController < ApplicationController

  before_filter :authenticate

  def index
    @user  = current_user
    @teams = Team.by_owner( current_user )
  end

  def create
    Team.find_or_create_by(:owner_id => current_user.ids, :name => params[:teams][:name])
    redirect_to settings_teams_path
  end

  def show
    @team = Team.where(:id => params[:id], :owner_id => current_user.ids).first
  end

  def add
    @team = Team.where(:id => params[:id], :owner_id => current_user.ids).first
    user = User.find_by_username params[:username]
    @team.add_member user
    redirect_to settings_teams_show_path(@team)
  end

  def remove
    @team = Team.where(:id => params[:id], :owner_id => current_user.ids).first
    user = User.find_by_username params[:username]
    @team.remove_member user
    redirect_to settings_teams_show_path(@team)
  end

  def destroy
    team = Team.where(:id => params[:id], :owner_id => current_user.ids)
    team.delete
    redirect_to settings_teams_path
  end

end
