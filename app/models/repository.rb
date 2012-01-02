class Repository
  include Mongoid::Document
  include Mongoid::Timestamps
  field :src, type: String
  field :repotype, type: String  
  
  embedded_in :product
    
  def as_json param
    {
      :src => self.src,
      :repotype => self.repotype
    }
  end
  
end