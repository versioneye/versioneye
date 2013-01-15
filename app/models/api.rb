class Api
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :api_key, type: String
  field :calls, type: Integer, default: 0

  validates :name, presence: true
  validates :api_key, presence: true, 
                      length: {minimum: 20, maximum: 20}, 
                      uniqueness: true

  def self.generate_api_key(length = 20)
    #as SecureRandom generated string is always 2 * length, we use twice smaller length
    length = (length / 2.0).round
    length = 1 if length < 1

    SecureRandom.hex(length)
  end

end
