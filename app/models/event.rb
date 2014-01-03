class Event

  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, type: String  # new_version, user_follow_user, user_follow_product, version_comment,

  field :prod_name    , type: String
  field :prod_version , type: String
  field :prod_key     , type: String
  field :language     , type: String
  field :prod_type    , type: String
  field :prod_group_id, type: String

  field :follower_id, type: String
  field :followed_id, type: String

  field :version_comment_id, type: String
  field :version_comment_user_id, type: String

end
