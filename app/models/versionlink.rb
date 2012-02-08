class Versionlink
  include Mongoid::Document
  include Mongoid::Timestamps
  field :uid, type: String
  field :link, type: String
  field :name, type: String
  
  embedded_in :version
  
  def as_json parameter
    {
      :name => self.name,
      :link => self.link,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end
  
end