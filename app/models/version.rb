
class Version < ActiveRecord::Base

  belongs_to :product,   :class_name => "Product"
  
  # has_many  :notifications, :through => :notification, :source => :version

  validates :product_id, :presence => true

end
