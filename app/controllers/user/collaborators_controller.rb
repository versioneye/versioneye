class User::CollaboratorsController < ApplicationController
  before_filter :authenticate

  def index
    render text: "o, you shouldnt see that."
  end

  def show
    p "#-- Showing collaborators:", params

    project = Project.find_by_id(params[:project_id])
    render json: project.collaborators
  end

  def create
    collaborator_info = params[:collaborator]
    project = Project.find_by_id params[:project_id]
    
    if project.nil?
      flash[:error] = "Failure: Cant add collaborator - wrong project id."
      redirect_to :back and return
    end

    user = User.find_by_email(collaborator_info[:email])
    
    new_collaborator = ProjectCollaborator.new project_id: project[:_id].to_s,
                                           owner_id: current_user[:_id].to_s
    
    if user.nil?
      #activate invitation
      new_collaborator[:invitation_email] = collaborator_info[:email]
      new_collaborator[:invitation_code] = UserService.create_random_token
    else
      #add to collaborator
      new_collaborator[:active] = true
      new_collaborator[:user_id] = user[:_id].to_s
    end

    new_collaborator.save
    project.collaborators << new_collaborator

    flash[:success] = "New collaborator is now added"
    redirect_to :back
  end

  def delete
    #remove only if user=owner, current_user==same_collaborator
    collaborator = ProjectCollaborator.find_by_id(params[:id])
    if collaborator.nil?
      flash[:error] = "No such collaborator anymore."
      redirect_to :back and return
    end

    if collaborator.owner.id == current_user.id or (!collaborator.nil? and collaborator.user.id == current_user.id)  
      flash[:success] = "Collaborator is now removed."
      collaborator.delete
    else
      flash[:error] = "You cant remove other peoples."
    end

    redirect_to :back and return
  end

  def invite
    #TODO: finish it 
  end
end
