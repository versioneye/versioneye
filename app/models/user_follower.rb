class UserFollower

  include Mongoid::Document
  include Mongoid::Timestamps

  field :follower_id, type: String  
  field :followed_id, type: String

  def followers( user_id )
    UserFollower.where( :followed_id => user_id )
    # TODO fetch only ids and than fetch user objects 
  end

  def following( user_id )
    UserFollower.where( :follower_id => user_id )
    # TODO fetch only ids and than fetch user objects 
  end

end