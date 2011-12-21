class Follower < ActiveRecord::Base

  belongs_to :user,      :class_name => "User"
  belongs_to :product,   :class_name => "Product"

  validates :user_id,    :presence => true
  validates :product_id, :presence => true
  
  def self.find_by_user_id_and_product(user_id, product_id)    
    follower = Follower.where("user_id = ? AND product_id = ?", user_id, product_id)
    return follower[0] unless follower.nil?
    return nil
  end

end