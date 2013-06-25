class ProductSecurityNotification
  include Mongoid::Document

  field :connection_type, type: String
  field :language, type: String
  field :root_product_id, type: String

  belongs_to :product
  has_one :security_notification

  scope :by_connection, ->(type_name){where(connection_type: type_name)}
  scope :by_language, ->(lang){where(language: lang)}

end
