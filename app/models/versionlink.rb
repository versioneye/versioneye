class Versionlink

  include Mongoid::Document
  include Mongoid::Timestamps

  field :prod_key, type: String
  field :version_id, type: String  
  field :link, type: String
  field :name, type: String
  field :manual, type: Boolean, :default => false
  
  def as_json parameter
    {
      :name => self.name,
      :link => self.link,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end

  def self.find_by(prod_key, link)
    Versionlink.where( prod_key: prod_key, link: link )[0]
  end

  def get_link
    if self.link.match(/^www.*/) != nil 
      return "http://#{self.link}"
    else 
      return self.link
    end
  end
  
end