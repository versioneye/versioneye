module OrganisationHelper


  def load_orga
    @organisation = Organisation.where(:name => params[:organisation_name]).first
  end


  def auth_org_member
    return true if current_user.admin == true
    return true if OrganisationService.member?(@organisation, current_user)
    flash[:error] = "You are not a member of this organisation. You don't have the permission for this operation."
    redirect_to organisations_path
    return false
  end


  def auth_org_owner
    return true if current_user.admin == true
    return true if OrganisationService.owner?(@organisation, current_user)
    flash[:error] = "You are not in the Owners team. You don't have the permission for this operation."
    redirect_to organisation_path(@organisation)
    return false
  end


  def is_orga_owner? orga, user
    return true if user.admin == true
    return true if OrganisationService.owner?(orga, user)
    return false
  end

  def auth_team_add_del
    @team = Team.where(:name => params[:id], :organisation_id => @organisation.ids).first
    return false if @team.nil?
    return true if current_user.admin == true
    return true if OrganisationService.owner?(@organisation, current_user)
    return true if @organisation.matanmtt == true && @team.is_member?( current_user )
    flash[:error] = "You are not authorized for this action."
    redirect_to organisation_team_path( @organisation, @team )
    return false
  end


end
