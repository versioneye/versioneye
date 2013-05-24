class UserFollower

  # TODO where used ?

  include Mongoid::Document
  include Mongoid::Timestamps

  field :follower_id, type: String
  field :followed_id, type: String

  def followers( user_id )
    follower_ids = UserFollower.all(conditions: { followed_id: user_id } ).distinct(:follower_id)
    return User.find_by_ids( follower_ids )
  end

  def following( user_id )
    followed_ids = UserFollower.all(conditions: { follower_id: user_id } ).distinct(:followed_id)
    return User.find_by_ids( followed_ids )
  end

end
