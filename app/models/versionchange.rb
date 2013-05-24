class Versionchange

  # TODO where used ?

  include Mongoid::Document
  include Mongoid::Timestamps

  field :prod_key, type: String
  field :version_id, type: String
  field :change, type: String

  def as_json parameter
    {
      :name => self.name,
      :link => self.link,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end

end
