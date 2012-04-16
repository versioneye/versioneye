class Follower

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :product_id, type: String  
  field :notification, type: Boolean
  
  validates_presence_of :user_id,    :message => "User is mandatory!"
  validates_presence_of :product_id, :message => "Product is mandatory!"
  
  def self.find_by_user_id_and_product(user_id, product_id)    
    Follower.first(conditions: { user_id: user_id, product_id: product_id } )
  end
  
  def self.find_by_product(product_id)
    Follower.all(conditions: { product_id: product_id } )
  end
  
  def self.find_notifications_by_user_id(user_id)    
    Follower.all(conditions: { user_id: user_id, notification: true } )
  end
  
  def self.find_by_user(user_id)
    Follower.all(conditions: { user_id: user_id } )
  end

  def self.find_followers_for_product(product_id)
    Follower.all(conditions: { product_id: product_id } ).distinct(:user_id)
  end
    
  def user
    User.find_by_id( self.user_id )
  end

end