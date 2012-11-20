class BillingAddress

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :street, type: String
  field :state, type: String
  field :zip, type: String
  field :country, type: String
  field :user_id, type: String

end