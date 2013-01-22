class ApiCall
  include Mongoid::Document
  include Mongoid::Timestamps

  field :api_key, type: String
  field :user_id, type: String
  field :fullpath, type: String
  field :ip,      type: String

  validates :api_key, presence: true
  validates :fullpath, presence: true

  scope :by_user, ->(user){ where(user_id: user.id.to_s) }
  scope :by_api_key, ->(api_key){ where(api_key: api_key) }
  scope :today, where(:created_at.gte => Date.today.midnight, 
                      :created_at.lt => Date.tomorrow.midnight)
end
