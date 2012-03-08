class FollowerSql < ActiveRecord::Base

  set_table_name "followers"

  belongs_to :user,      :class_name => "UserSql"

  validates :user_id,    :presence => true
  validates :product_id, :presence => true
  
  def self.find_by_user_id_and_product(user_id, product_id)    
    Follower.find(:first, :conditions => ["user_id = ? AND product_id = ?", user_id, product_id])
  end
  
  def self.find_by_product(product_id)
    Follower.find(:all, :conditions => ["product_id = ?", product_id])
  end
  
  def self.find_notifications_by_user_id(user_id)    
    Follower.find(:all, :conditions => ["user_id = ? AND notification is true", user_id])
  end
  
  def self.migrate_to_mongo
    followers = FollowerSql.all
    followers.each do |follower|
      p "follower: #{follower.id}"
      fol = Follower.new
      fol.user_id = follower.user_id
      fol.product_id = follower.product_id
      fol.notification = follower.notification
      fol.save
    end
  end

end