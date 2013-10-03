class Api

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :api_key, type: String
  field :calls  , type: Integer, default: 0

  validates :user_id, presence: true
  validates :api_key, presence: true,
                      length: {minimum: 20, maximum: 20},
                      uniqueness: true

  def create_new(user)
    new_api = Api.new(user_id: user[:_id].to_s)
    new_api.generate_api_key!

    new_api.save
    new_api
  end

  def self.generate_api_key(length = 20)
    # TODO As SecureRandom generated string is always 2 * length, we use twice smaller length
    length = (length / 2.0).round
    length = 1 if length < 1
    SecureRandom.hex(length)
  end

  def generate_api_key!(length =  20)
      api_key = Api.generate_api_key(length)
      self.api_key = api_key
  end

end
