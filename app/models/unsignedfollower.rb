class Unsignedfollower < ActiveRecord::Base

  belongs_to :unsigneduser,      :class_name => "Unsigneduser"
  belongs_to :product,           :class_name => "Product"

  validates :unsigneduser_id,    :presence => true
  validates :product_id,         :presence => true
  
  def self.find_by_unsigneduser_id_and_product(user_id, product_id)    
    follower = Unsignedfollower.where("unsigneduser_id = ? AND product_id = ?", user_id, product_id)
    return follower[0] unless follower.nil?
    return nil
  end

end