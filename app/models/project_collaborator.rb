class ProjectCollaborator

  include Mongoid::Document
  include Mongoid::Timestamps

  field :project_id, type: String
  field :user_id   , type: String # the user who is added as collaborator
  field :owner_id  , type: String # the owner of the project
  field :caller_id , type: String # another contributor can add more contributors

  field :active, type: Boolean, default: false

  field :invitation_email, type: String
  field :invitation_code , type: String
  field :invitation_sent , type: Boolean, default: false

  field :period, type: String, default: Project::A_PERIOD_WEEKLY

  belongs_to :project

  validates_presence_of :project_id
  validates_presence_of :owner_id
  validates_presence_of :caller_id

  scope :by_user, ->(user){ any_of({user_id: user.id.to_s},
                                   {invitation_email: user[:email]}) }

  def self.find_by_id(id)
    self.where(_id: id).shift
  end

  def self.collaborator?(project_id, user_id)
    self.where(project_id: project_id.to_s, user_id: user_id.to_s).exists?
  end

  def user
    User.find_by_id(self[:user_id])
  end

  def owner
    User.find_by_id(self[:owner_id])
  end

  def caller
    User.find_by_id(self[:caller_id])
  end

  def owner?(current_user)
    return false if current_user.nil? or !current_user.has_attribute?(:_id)
    self.owner_id == current_user.id.to_s
  end

  def current?(user)
    return false if user.nil?
    return false if self[:user_id].nil?
    self[:user_id].to_s == user[:_id].to_s
  end

  def accepted?(current_user)
    return false if current_user.nil? or !current_user.has_attribute?(:_id)
    self[:active] && (self.user_id == current_user.id.to_s)
  end

  def not_accepted?(current_user)
    not accepted?(current_user)
  end

end
