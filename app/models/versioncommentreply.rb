class Versioncommentreply

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :fullname, type: String
  field :username, type: String
  field :comment, type: String

  embedded_in :versioncomment
  

end