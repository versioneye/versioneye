class Versionarchive

  include Mongoid::Document
  include Mongoid::Timestamps

  field :language  , type: String
  field :prod_key  , type: String # TODO_vc
  field :version_id, type: String
  field :link      , type: String
  field :name      , type: String

  def as_json parameter
    {
      :name => self.name,
      :link => self.link,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end

  def self.archives(lang, prod_key, version)
    Versionarchive.all(conditions: { language: lang, prod_key: prod_key, version_id: version}).asc(:name)
  end

end
