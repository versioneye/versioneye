class SecurityNotification

  include Mongoid::Document

  field :cve_id       , type: String
  field :summary      , type: String
  field :published    , type: DateTime
  field :last_modified, type: DateTime
  field :summary, type: String

  field :metrics
  belongs_to :product_security_notification

  #embeds_many :softwares
end
