class Version
  include Mongoid::Document
  include Mongoid::Timestamps
  field :_id, type: String
  field :version, type: String
  field :link, type: String
  
  embedded_in :product
  
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