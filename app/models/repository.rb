class Repository < ActiveRecord::Base

  belongs_to :repotype
  
  def as_json param
    {
      :name => self.name,
      :src => self.src,
      :repotype => self.repotype.name
    }
  end
  
end