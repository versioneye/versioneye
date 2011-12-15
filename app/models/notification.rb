class Notification < ActiveRecord::Base

  belongs_to :user,           :class_name => "User"
  belongs_to :unsigneduser,   :class_name => "Unsigneduser"  
  belongs_to :version,        :class_name => "Version"

  validates :version_id, :presence => true

end