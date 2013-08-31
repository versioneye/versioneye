class Lottery
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :selection, type: Array
  field :active, type: Boolean, default: true
  field :won, type: Boolean, default: false
  field :prize, type: String

  field :migrated, default: false

  scope :by_user, ->(user){where(user_id: user[:_id].to_s)}
end
