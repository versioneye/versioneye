require 'spec_helper'

describe ProjectCollaborator do

  describe "collaborator?" do

    it "returns the right values" do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :caller_id => owner._id )
      collaborator.save
      project.collaborators << collaborator

      ProjectCollaborator.collaborator?(project.id, user.id).should be_false
      collaborator.user_id = user.id.to_s
      collaborator.save
      ProjectCollaborator.collaborator?(project.id, user.id).should be_true
    end

  end

end
