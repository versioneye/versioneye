
class Follower < ActiveRecord::Base

  belongs_to :user,      :class_name => "User"
  belongs_to :product,   :class_name => "Product"

  validates :user_id,    :presence => true
  validates :product_id, :presence => true

end
