class Version < ActiveRecord::Base

  belongs_to :product,   :class_name => "Product"

  validates :product_id, :presence => true
  
  def as_json parameter
    {
      :version => self.version,
      :link => self.link,
      :created_at => self.created_at,
      :updated_at => self.updated_at
    }
  end

end