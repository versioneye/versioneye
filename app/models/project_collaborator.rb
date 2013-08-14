class ProjectCollaborator
  include Mongoid::Document
  include Mongoid::Timestamps

  A_PERIOD_WEEKLY = "weekly"
  A_PERIOD_DAILY  = "daily"

  field :project_id, type: String
  field :user_id, type: String
  field :owner_id, type: String

  field :active, type: Boolean, default: false

  field :invitation_email, type: String
  field :invitation_code, type: String
  field :period, type: String, default: A_PERIOD_WEEKLY
  field :emails, type: Array
  
  belongs_to :project

  def self.find_by_id(id)
    self.where(_id: id).shift
  end
  
  def user
    User.find_by_id(self[:user_id])
  end

  def owner
    User.find_by_id(self[:owner_id])
  end
end
