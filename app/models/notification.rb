
class Notification < ActiveRecord::Base

  belongs_to :user,      :class_name => "User"
  belongs_to :version,   :class_name => "Version"

  validates :user_id,    :presence => true
  validates :version_id, :presence => true

end
