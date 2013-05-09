# TODO delete after cleared the db 
class Follower

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :product_id, type: String  
  
  
  validates_presence_of :user_id,    :message => "User is mandatory!"
  validates_presence_of :product_id, :message => "Product is mandatory!"
  
  def self.find_by_product(product_id)
    Follower.all(conditions: { product_id: product_id } )
  end
  
  def self.find_by_user(user_id)
    Follower.all(conditions: { user_id: user_id } )
  end

  def self.find_follower_ids_for_product(product_id)
    Follower.all(conditions: { product_id: product_id } ).distinct(:user_id)
  end

  def self.find_product_ids_for_user(user_id)
    Follower.all(conditions: { user_id: user_id } ).distinct(:product_id)
  end

  def self.unfollow_all_by_user(user_id)
    followers = Follower.all(conditions: { user_id: user_id } )
    if !followers.nil? && !followers.empty?
      followers.each do |follower|
        follower.remove
      end
    end
  end
    
  def user
    User.find_by_id( self.user_id )
  end

end
