class Follower < ActiveRecord::Base

  belongs_to :user,      :class_name => "User"

  validates :user_id,    :presence => true
  validates :product_id, :presence => true
  
  def self.find_by_user_id_and_product(user_id, product_id)    
    Follower.find(:first, :conditions => ["user_id = ? AND product_id = ?", user_id, product_id])
  end
  
  def self.find_by_product(product_id)
    Follower.find(:all, :conditions => ["product_id = ?", product_id])
  end

end