class Notification < ActiveRecord::Base

  belongs_to :user,           :class_name => "User"
  belongs_to :unsigneduser,   :class_name => "Unsigneduser"  

  validates :product_id, :presence => true
  validates :version_id, :presence => true

end