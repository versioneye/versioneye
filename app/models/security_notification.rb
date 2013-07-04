class SecurityNotification

  include Mongoid::Document
  field :summary, type: String

  field :metrics
  belongs_to :product_security_notification

  #embeds_many :softwares
end
